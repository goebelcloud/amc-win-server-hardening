<#
.SYNOPSIS
  Hydrate standard and enhanced policy definitions for this package.

.DESCRIPTION
  This script reads package-local metadata plus the central policy templates and renders:
    - deployIfNotExists.json
    - deployIfNotExists.enhanced.json

  The only Azure Policy parameters remain:
    - effect
    - assignmentType
    - requiredUserAssignedIdentityResourceId (enhanced only)

  Package artifact values such as contentUri and contentHash are synchronized into
  policy-metadata.json first and then injected into the rendered policies.
#>

[CmdletBinding()]
param(
  [Parameter()]
  [string]$ConfigPath,

  [Parameter()]
  [string]$ContentUriBase,

  [Parameter()]
  [string]$RequiredUamiResourceId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-PackageHelperScript {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$StartDirectory
  )

  $currentDirectory = Resolve-Path -Path $StartDirectory
  while ($true) {
    $directCandidate = Join-Path -Path $currentDirectory -ChildPath 'package-metadata.helpers.ps1'
    if (Test-Path -Path $directCandidate) {
      return $directCandidate
    }

    $packagesCandidate = Join-Path -Path (Join-Path -Path $currentDirectory -ChildPath 'packages') -ChildPath 'package-metadata.helpers.ps1'
    if (Test-Path -Path $packagesCandidate) {
      return $packagesCandidate
    }

    $parentDirectory = Split-Path -Path $currentDirectory -Parent
    if ($parentDirectory -eq $currentDirectory) { break }
    $currentDirectory = $parentDirectory
  }

  throw 'Could not find packages/package-metadata.helpers.ps1.'
}

# Recursively replace placeholder tokens inside JSON template objects.
function Resolve-TemplateObject {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    $InputObject,

    [Parameter(Mandatory)]
    [hashtable]$Replacements
  )

  if ($null -eq $InputObject) { return $null }

  if ($InputObject -is [string]) {
    if ($Replacements.ContainsKey($InputObject)) {
      return $Replacements[$InputObject]
    }

    return $InputObject
  }

  if ($InputObject -is [System.Collections.IDictionary]) {
    $resolvedMap = [ordered]@{}
    foreach ($key in $InputObject.Keys) {
      $resolvedMap[$key] = Resolve-TemplateObject -InputObject $InputObject[$key] -Replacements $Replacements
    }
    return $resolvedMap
  }

  if (($InputObject -is [System.Collections.IEnumerable]) -and -not ($InputObject -is [string])) {
    $resolvedItems = @()
    foreach ($item in $InputObject) {
      $resolvedItems += ,(Resolve-TemplateObject -InputObject $item -Replacements $Replacements)
    }
    return $resolvedItems
  }

  if ($InputObject.PSObject -and $InputObject.PSObject.Properties.Count -gt 0) {
    $resolvedObject = [ordered]@{}
    foreach ($property in $InputObject.PSObject.Properties) {
      $resolvedObject[$property.Name] = Resolve-TemplateObject -InputObject $property.Value -Replacements $Replacements
    }
    return [pscustomobject]$resolvedObject
  }

  return $InputObject
}

# Render one template file to a concrete JSON document and validate the JSON before writing it.
function Render-TemplateFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$TemplatePath,

    [Parameter(Mandatory)]
    [hashtable]$Replacements,

    [Parameter(Mandatory)]
    [string]$OutputPath
  )

  $templateObject = Get-Content -Path $TemplatePath -Raw | ConvertFrom-Json -Depth 100
  $resolvedObject = Resolve-TemplateObject -InputObject $templateObject -Replacements $Replacements
  $jsonText = $resolvedObject | ConvertTo-Json -Depth 100

  $null = $jsonText | ConvertFrom-Json -Depth 100
  Set-Content -Path $OutputPath -Value $jsonText -Encoding UTF8
}

# Resolve the package root and import shared helpers.
$packageRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$helperPath = Find-PackageHelperScript -StartDirectory $packageRoot
. $helperPath

$packageName = Split-Path -Path $packageRoot -Leaf
$metadataPath = Join-Path -Path $packageRoot -ChildPath 'policy-metadata.json'
if (-not (Test-Path -Path $metadataPath)) {
  throw ('policy-metadata.json not found: {0}' -f $metadataPath)
}

# Resolve central configuration and refresh metadata before rendering templates.
if (-not $ConfigPath) {
  $ConfigPath = Find-RepositoryConfig -StartDirectory $packageRoot
}

$config = Read-JsonFileOrdered -Path $ConfigPath
if (-not $config.OutputPaths) {
  throw 'OutputPaths missing in packages/machine-configuration.config.json.'
}

$null = Sync-PackageMetadata -PackageRoot $packageRoot -ConfigPath $ConfigPath -ContentUriBaseOverride $ContentUriBase
$metadata = Read-JsonFileOrdered -Path $metadataPath
$artifactInfo = Get-PackageArtifactInfo -PackageRoot $packageRoot -ConfigPath $ConfigPath -ContentUriBaseOverride $ContentUriBase

if (-not $ContentUriBase) {
  $ContentUriBase = [string]$config.ContentUriBase
}
if (-not $RequiredUamiResourceId) {
  $RequiredUamiResourceId = [string]$config.RequiredUamiResourceId
}

# Fail fast when required runtime inputs are still placeholders.
if (-not $ContentUriBase -or $ContentUriBase -like '*<storageaccount>*') {
  throw 'ContentUriBase is not set. Update packages/machine-configuration.config.json or pass -ContentUriBase.'
}
if (-not $RequiredUamiResourceId -or $RequiredUamiResourceId -like '*/subscriptions/<sub>*') {
  throw 'RequiredUamiResourceId is not set. Update packages/machine-configuration.config.json or pass -RequiredUamiResourceId.'
}
if (-not $artifactInfo.artifactPresent) {
  throw ('Package ZIP not found. Build the package first: {0}' -f $artifactInfo.zipPath)
}

# Resolve output folders and template locations.
$repositoryRoot = Split-Path -Path (Split-Path -Path $ConfigPath -Parent) -Parent
$policyRoot = Join-Path -Path $repositoryRoot -ChildPath $config.OutputPaths.PolicyOutputRoot
$templateRoot = Join-Path -Path $repositoryRoot -ChildPath 'policy-templates'

$perPackageOutputMode = [string]$config.OutputPaths.PerPackageOutputMode
if (-not $perPackageOutputMode) {
  $perPackageOutputMode = 'byControlId'
}
$outputFolderName = if ($perPackageOutputMode -eq 'byPackageFolder') { $packageName } else { [string]$metadata.controlId }

$policyOutputPath = Join-Path -Path $policyRoot -ChildPath $outputFolderName
New-Item -ItemType Directory -Path $policyOutputPath -Force | Out-Null

$contentUri = [string]$metadata.contentUri
if (-not $contentUri) {
  $contentUri = [string]$artifactInfo.contentUri
}
$contentHash = [string]$metadata.contentHash
if (-not $contentHash) {
  $contentHash = [string]$artifactInfo.contentHash
}

# Build the display names and policy names from metadata and central config.
$policyDisplayPrefix = [string]$config.PolicyDisplayPrefix
$displayNameBase = if ($policyDisplayPrefix) {
  '{0}{1} - {2}' -f $policyDisplayPrefix, $metadata.controlId, $metadata.displayNameSuffix
}
else {
  '{0} - {1}' -f $metadata.controlId, $metadata.displayNameSuffix
}

$standardPolicyName = [string]$metadata.definitionName
$enhancedPolicyName = '{0}-enhanced' -f $metadata.definitionName
$assignmentNameExpression = "[concat('{0}`$pid', uniqueString(policy().assignmentId, policy().definitionReferenceId))]" -f $metadata.guestConfigurationName

# Convert package-local special values into the configuration-parameter structures expected by the templates.
$metadataConfigurationParameters = @{}
$deploymentConfigurationParameters = @()
if ($metadata.packageParameters) {
  foreach ($parameterEntry in $metadata.packageParameters.GetEnumerator()) {
    $parameterName = [string]$parameterEntry.Key
    $parameterValue = $parameterEntry.Value
    if ($parameterValue.configurationParameterSelector) {
      $metadataConfigurationParameters[$parameterName] = [string]$parameterValue.configurationParameterSelector
      $deploymentConfigurationParameters += @{
        name  = [string]$parameterValue.configurationParameterSelector
        value = [string]$parameterValue.defaultValue
      }
    }
  }
}

$templateReplacementsCommon = @{
  '__POLICY_NAME__'                     = [string]$standardPolicyName
  '__DISPLAY_NAME__'                   = [string]$displayNameBase
  '__DESCRIPTION__'                    = [string]$metadata.descriptionText
  '__CONTROL_ID__'                     = [string]$metadata.controlId
  '__BASE_CONTROL_ID__'                = [string]$metadata.baseControlId
  '__GUEST_CONFIGURATION_NAME__'       = [string]$metadata.guestConfigurationName
  '__ASSIGNMENT_TYPE_DEFAULT__'        = [string]$metadata.assignmentTypeDefault
  '__CONTENT_URI__'                    = [string]$contentUri
  '__CONTENT_HASH__'                   = [string]$contentHash
  '__CONTENT_MANAGED_IDENTITY__'       = [string]$RequiredUamiResourceId
  '__METADATA_CONFIGURATION_PARAMETERS__'   = $metadataConfigurationParameters
  '__DEPLOYMENT_CONFIGURATION_PARAMETERS__' = $deploymentConfigurationParameters
  '__ASSIGNMENT_NAME_EXPRESSION__'     = [string]$assignmentNameExpression
  '__REQUIRED_UAMI_DEFAULT__'          = [string]$RequiredUamiResourceId
}

$standardTemplatePath = Join-Path -Path $templateRoot -ChildPath 'deployIfNotExists.template.json'
$enhancedTemplatePath = Join-Path -Path $templateRoot -ChildPath 'deployIfNotExists.enhanced.template.json'

$standardReplacements = @{}
$templateReplacementsCommon.Keys | ForEach-Object { $standardReplacements[$_] = $templateReplacementsCommon[$_] }

$enhancedReplacements = @{}
$templateReplacementsCommon.Keys | ForEach-Object { $enhancedReplacements[$_] = $templateReplacementsCommon[$_] }
$enhancedReplacements['__POLICY_NAME__'] = [string]$enhancedPolicyName
$enhancedReplacements['__DISPLAY_NAME__'] = '{0} (enhanced)' -f $displayNameBase

# Render both supported policy variants.
Render-TemplateFile `
  -TemplatePath $standardTemplatePath `
  -Replacements $standardReplacements `
  -OutputPath (Join-Path -Path $policyOutputPath -ChildPath 'deployIfNotExists.json')

Render-TemplateFile `
  -TemplatePath $enhancedTemplatePath `
  -Replacements $enhancedReplacements `
  -OutputPath (Join-Path -Path $policyOutputPath -ChildPath 'deployIfNotExists.enhanced.json')

# Refresh the runtime catalog after rendering.
$catalogPath = Update-PackageCatalog -ConfigPath $ConfigPath
Write-Host -Object ('Hydrated policy definitions for {0}' -f $packageName) -ForegroundColor Green
Write-Host -Object ('Updated package metadata: {0}' -f $metadataPath) -ForegroundColor Green
Write-Host -Object ('Updated package catalog: {0}' -f $catalogPath) -ForegroundColor Green
