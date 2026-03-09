<#
.SYNOPSIS
  Hydrate policy JSON for this package (enhanced + non-enhanced) (win-server-ACCT-005).

.DESCRIPTION
  Reads templates under:
    - policy/deployIfNotExists.enhanced.sample.json
    - policy/deployIfNotExists.json
  Replaces placeholders:
    - __CONTENT_URI__  -> <ContentUriBase>/<ControlId>.zip
    - __CONTENT_HASH__ -> SHA256 of the built package ZIP
    - __UAMI_RESOURCE_ID__ -> required UAMI resource ID

  The hydrated policy is written to the configured policy output folder (never into the package folder):
    OutputPaths.PolicyOutputRoot/<ControlId>/deployIfNotExists.enhanced.json
    OutputPaths.PolicyOutputRoot/<ControlId>/deployIfNotExists.json

  Defaults are read from:
    packages/machine-configuration.config.json

.NOTES
  File: hydrate-policy.ps1
  Package: win-server-ACCT-005 - Password must meet complexity requirements
  Purpose: Hydrates Azure Policy JSON templates (enhanced + non-enhanced) for the setting "Password must meet complexity requirements" (win-server-ACCT-005).
  Version: 1.0.0
#>

[CmdletBinding()]
param(
  # Optional override. If not specified, the script searches upwards for packages/machine-configuration.config.json
  [string]$ConfigPath,

  # Optional overrides (defaults come from packages/machine-configuration.config.json)
  [string]$ContentUriBase,
  [string]$RequiredUamiResourceId
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Find-RepositoryConfig {
  param([string]$StartDirectory)

  $current = Resolve-Path $StartDirectory
  while ($true) {
    $candidate = Join-Path $current "machine-configuration.config.json"
    if (Test-Path $candidate) { return $candidate }

    $parent = Split-Path $current -Parent
    if ($parent -eq $current) { break }
    $current = $parent
  }

  throw "Could not find packages/machine-configuration.config.json by searching up from: $StartDirectory"
}

$packageRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$packageFolderName = Split-Path -Leaf $packageRoot

# ControlId used for packaging, ZIP naming, and contentUri is taken directly from the folder name prefix.
# Example: "win-server-ACCT-001"
$controlId = ($packageFolderName -split "__")[0]

if (-not $ConfigPath) {
  $ConfigPath = Find-RepositoryConfig -StartDirectory $packageRoot
}

$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

# BaseControlId is used ONLY for the Azure Policy displayName (human readable).
$baseControlIdMatch = [regex]::Match($controlId, "([A-Z]{2,6}-\d{3})$")
$baseControlId = if ($baseControlIdMatch.Success) { $baseControlIdMatch.Groups[1].Value } else { $controlId }
$policyDisplayPrefix = $config.ControlIdPolicyPrefix
$policyDisplayId = if ($policyDisplayPrefix) { $policyDisplayPrefix + $baseControlId } else { $controlId }
# Setting metadata (used for readable policy displayName/description)
$settingTitle = "Password must meet complexity requirements"
$settingPath  = "Account Policies\Password Policy"
$settingSuggestedValue = "Enabled"




# Detailed hydration steps for win-server-ACCT-005 (Password must meet complexity requirements):
#   1) Locate the built package ZIP in the configured PackageZipOutputRoot and calculate SHA256 (contentHash).
#   2) Build the contentUri: <ContentUriBase>/win-server-ACCT-005.zip
#   3) Replace placeholders in policy/deployIfNotExists.enhanced.sample.json:
#        __CONTENT_URI__      -> resolved contentUri
#        __CONTENT_HASH__     -> computed SHA256 hash
#        __UAMI_RESOURCE_ID__ -> RequiredUamiResourceId (used by Machine Configuration to download the ZIP from storage)
#   4) Write the hydrated enhanced policy JSON to the configured PolicyOutputRoot (never into the package folder).
#   5) Azure Policy parameters (effect, assignmentType, requiredUserAssignedIdentityResourceId) remain parameters so Terraform can set them at assignment time.
if (-not $ContentUriBase) { $ContentUriBase = $config.ContentUriBase }
if (-not $RequiredUamiResourceId) { $RequiredUamiResourceId = $config.RequiredUamiResourceId }

if (-not $ContentUriBase -or $ContentUriBase -like "*<storageaccount>*") {
  throw "ContentUriBase is not set. Update packages/machine-configuration.config.json (ContentUriBase) or pass -ContentUriBase."
}

if (-not $RequiredUamiResourceId -or $RequiredUamiResourceId -like "*/subscriptions/<sub>*") {
  throw "RequiredUamiResourceId is not set. Update packages/machine-configuration.config.json (RequiredUamiResourceId) or pass -RequiredUamiResourceId."
}

if (-not $config.OutputPaths) {
  throw "OutputPaths missing in packages/machine-configuration.config.json."
}

# Derive repo root from config location: <repoRoot>\packages\machine-configuration.config.json
$repoRoot = Split-Path -Path (Split-Path -Path $ConfigPath -Parent) -Parent

$packageZipOutputRoot = Join-Path $repoRoot $config.OutputPaths.PackageZipOutputRoot
$policyOutputRoot     = Join-Path $repoRoot $config.OutputPaths.PolicyOutputRoot

$perPackageMode = $config.OutputPaths.PerPackageOutputMode
if (-not $perPackageMode) { $perPackageMode = "byControlId" }

switch ($perPackageMode) {
  "byPackageFolder" { $outFolder = $packageFolderName }
  default           { $outFolder = $controlId }
}

$expectedZipPath = Join-Path (Join-Path $packageZipOutputRoot $outFolder) ("{0}.zip" -f $controlId)
if (-not (Test-Path $expectedZipPath)) {
  throw ("Package ZIP not found: {0}. Build the package first." -f $expectedZipPath)
}

$hash = (Get-FileHash -Path $expectedZipPath -Algorithm SHA256).Hash.ToLowerInvariant()
$contentUri = ("{0}/{1}.zip" -f $ContentUriBase.TrimEnd("/"), $controlId)

$templatePath = Join-Path $packageRoot "policy\deployIfNotExists.enhanced.sample.json"
if (-not (Test-Path $templatePath)) {
  throw ("Policy template not found: {0}" -f $templatePath)
}

$templateJson = Get-Content -Path $templatePath -Raw
$templateJson = $templateJson.Replace("__CONTENT_URI__", $contentUri)
$templateJson = $templateJson.Replace("__CONTENT_HASH__", $hash)
$templateJson = $templateJson.Replace("__UAMI_RESOURCE_ID__", $RequiredUamiResourceId)

$outPolicyFolder = Join-Path $policyOutputRoot $outFolder
New-Item -Path $outPolicyFolder -ItemType Directory -Force | Out-Null

$outPath = Join-Path $outPolicyFolder "deployIfNotExists.enhanced.json"
$outPortalPath = ($outPath -replace "\.json$", ".portal.json")

# Azure Portal note:
# - When you paste JSON into the Portal "JSON" editor for a policy definition, the Portal expects the *properties object*
#   (displayName/mode/metadata/parameters/policyRule) and wraps it in "properties" itself.
# - Therefore we emit a second file without the outer { "properties": { ... } } wrapper.
$templateObject = $templateJson | ConvertFrom-Json -Depth 50
$templateObject.properties.displayName = ("{0} - {1} (Machine Configuration)" -f $policyDisplayId, $settingTitle)
($templateObject | ConvertTo-Json -Depth 50) | Set-Content -Path $outPath -Encoding UTF8
($templateObject.properties | ConvertTo-Json -Depth 50) | Set-Content -Path $outPortalPath -Encoding UTF8

# --- Non-enhanced policy hydration (deployIfNotExists.json) ---
# This variant removes the additional prerequisite gates used in the enhanced sample policy.
# Use this when you want Azure Policy to deploy the Guest Configuration assignment without
# requiring identity/UAMI checks in the policy 'if' clause (prereqs can be enforced separately).
$baseTemplatePath = Join-Path $packageRoot "policy\deployIfNotExists.json"
if (-not (Test-Path $baseTemplatePath)) {
  throw ("Policy template not found: {0}" -f $baseTemplatePath)
}

$baseTemplateJson = Get-Content -Path $baseTemplatePath -Raw
$baseTemplateJson = $baseTemplateJson.Replace("__CONTENT_URI__", $contentUri)
$baseTemplateJson = $baseTemplateJson.Replace("__CONTENT_HASH__", $hash)
$baseTemplateJson = $baseTemplateJson.Replace("__UAMI_RESOURCE_ID__", $RequiredUamiResourceId)

$outBasePath = Join-Path $outPolicyFolder "deployIfNotExists.json"
$outBasePortalPath = ($outBasePath -replace "\.json$", ".portal.json")

$baseTemplateObject = $baseTemplateJson | ConvertFrom-Json -Depth 50
$baseTemplateObject.properties.displayName = ("{0} - {1} (Machine Configuration)" -f $policyDisplayId, $settingTitle)
($baseTemplateObject | ConvertTo-Json -Depth 50) | Set-Content -Path $outBasePath -Encoding UTF8
($baseTemplateObject.properties | ConvertTo-Json -Depth 50) | Set-Content -Path $outBasePortalPath -Encoding UTF8


Write-Host "Hydrated policies written:" -ForegroundColor Green
Write-Host ("  Enhanced JSON:       {0}" -f $outPath)
Write-Host ("  Enhanced Portal:     {0}" -f $outPortalPath)
Write-Host ("  Non-enhanced JSON:   {0}" -f $outBasePath)
Write-Host ("  Non-enhanced Portal: {0}" -f $outBasePortalPath)
Write-Host ("contentUri:  {0}" -f $contentUri)
Write-Host ("contentHash: {0}" -f $hash)
Write-Host ("required UAMI: {0}" -f $RequiredUamiResourceId)