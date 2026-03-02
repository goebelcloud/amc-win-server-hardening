<#
.SYNOPSIS
  Hydrate the enhanced policy JSON for this package (win-server-SECO-001).

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
  Package: win-server-SECO-001 - Accounts: Limit local account use of blank passwords to console logon only
  Purpose: Hydrates the enhanced Azure Policy JSON template for the setting "Accounts: Limit local account use of blank passwords to console logon only" (win-server-SECO-001).
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
$settingTitle = "Accounts: Limit local account use of blank passwords to console logon only"
$settingPath  = "Local Policies\Security Options"
$settingSuggestedValue = "Enabled"



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
$templateObject = $templateJson | ConvertFrom-Json -Depth 50
$templateObject.properties.displayName = ("{0} - {1} (Machine Configuration)" -f $policyDisplayId, $settingTitle)
($templateObject | ConvertTo-Json -Depth 50) | Set-Content -Path $outPath -Encoding UTF8

Write-Host ("Hydrated policy written: {0}" -f $outPath) -ForegroundColor Green
Write-Host ("contentUri:  {0}" -f $contentUri)
Write-Host ("contentHash: {0}" -f $hash)
Write-Host ("required UAMI: {0}" -f $RequiredUamiResourceId)