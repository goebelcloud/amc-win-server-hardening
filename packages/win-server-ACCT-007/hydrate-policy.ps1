<#
.SYNOPSIS
  Hydrate the enhanced policy JSON for this package (win-server-ACCT-007).

.DESCRIPTION
  Reads the template under: policy/deployIfNotExists.enhanced.sample.json
  Replaces placeholders:
    - __CONTENT_URI__  -> <ContentUriBase>/<ControlId>.zip
    - __CONTENT_HASH__ -> SHA256 of the built package ZIP
    - __UAMI_RESOURCE_ID__ -> required UAMI resource ID

  The hydrated policy is written to the configured policy output folder (never into the package folder):
    OutputPaths.PolicyOutputRoot/<ControlId>/deployIfNotExists.enhanced.json   (default)

  Defaults are read from:
    packages/machine-configuration.config.json

.NOTES
  File: hydrate-policy.ps1
  Package: win-server-ACCT-007 - Account lockout threshold
  Purpose: Hydrates the enhanced Azure Policy JSON template for the setting "Account lockout threshold" (win-server-ACCT-007).
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
$settingTitle = "Account lockout threshold"
$settingPath  = "Account Policies\Account Lockout Policy"
$settingSuggestedValue = "10 invalid logon attempts (WS2025 baseline uses 3; test before lowering)"




# Detailed hydration steps for win-server-ACCT-007 (Account lockout threshold):
#   1) Locate the built package ZIP in the configured PackageZipOutputRoot and calculate SHA256 (contentHash).
#   2) Build the contentUri: <ContentUriBase>/win-server-ACCT-007.zip
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

Write-Host ("Hydrated policy written: {0}" -f $outPath) -ForegroundColor Green
Write-Host ("contentUri:  {0}" -f $contentUri)
Write-Host ("contentHash: {0}" -f $hash)
Write-Host ("required UAMI: {0}" -f $RequiredUamiResourceId)