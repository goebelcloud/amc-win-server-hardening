<#
.SYNOPSIS
  Build this Machine Configuration package (win-server-SECO-008).

.DESCRIPTION
  - Compiles the DSC configuration to a MOF (localhost.mof)
  - Creates the Machine Configuration package ZIP
  - Optionally generates the baseline Azure Policy JSON via New-GuestConfigurationPolicy
    (only if ContentUriBase and RequiredUamiResourceId are configured)

  IMPORTANT:
  - No build outputs are written inside the package folder.
  - All outputs are written to the folders configured in: packages/machine-configuration.config.json (OutputPaths)

.NOTES
  File: build.ps1
  Package: win-server-SECO-008 - Network security: Do not store LAN Manager hash value on next password change
  Purpose: Builds the Machine Configuration artifacts for the setting "Network security: Do not store LAN Manager hash value on next password change" (win-server-SECO-008).
  Version: 1.0.0
#>

[CmdletBinding()]
param(
  # Machine Configuration package type ("Audit" or "AuditAndSet")
  [Parameter(Mandatory=$false)]
  [ValidateSet("Audit","AuditAndSet")]
  [string]$PackageType = "AuditAndSet",

  # Policy mode used for the baseline policy JSON (New-GuestConfigurationPolicy)
  [Parameter(Mandatory=$false)]
  [ValidateSet("Audit","ApplyAndMonitor","ApplyAndAutoCorrect")]
  [string]$PolicyMode,

  # Optional overrides (defaults come from packages/machine-configuration.config.json)
  [Parameter(Mandatory=$false)]
  [string]$ContentUriBase,

  [Parameter(Mandatory=$false)]
  [string]$UserAssignedIdentityResourceId,

  # Rebuild even if a ZIP already exists in the output folder
  [Parameter(Mandatory=$false)]
  [switch]$ForceRebuild
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

# Package context
$packageRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$packageFolderName = Split-Path -Leaf $packageRoot
$controlId = ($packageFolderName -split "__")[0]
$baseControlIdMatch = [regex]::Match($controlId, "([A-Z]{2,6}-\d{3})$")
$baseControlId = if ($baseControlIdMatch.Success) { $baseControlIdMatch.Groups[1].Value } else { $controlId }
$packageName = $controlId
$packageVersion = "1.0.0"

# Setting metadata (used for readable policy displayName/description)
$settingTitle = "Network security: Do not store LAN Manager hash value on next password change"
$settingPath  = "Local Policies\Security Options"
$settingSuggestedValue = "Enabled"



# Detailed build steps for win-server-SECO-008 (Network security: Do not store LAN Manager hash value on next password change):
#   1) Read repository configuration (packages/machine-configuration.config.json) to resolve output folders and defaults.
#      - PolicyMode controls the default remediation behavior in the generated *baseline* policy (if generated).
#      - ContentUriBase and RequiredUamiResourceId are used only when generating baseline policy JSON.
#   2) Compile the DSC configuration 'SECO_008_Network_security_Do_not_store_LAN_Manager_hash_valu' to produce a node MOF for localhost.
#      - Most common output: <MofOutputPath>\localhost.mof
#   3) Create the Machine Configuration package ZIP 'win-server-SECO-008.zip' using New-GuestConfigurationPackage.
#      - The ZIP includes the compiled MOF plus any DSC resource modules referenced by Configuration.ps1.
#      - Those modules must be installed on the authoring VM; they are shipped in the ZIP so the target VM does not need preinstalled DSC modules.
#   4) If ContentUriBase and RequiredUamiResourceId are configured (not placeholders), generate baseline Azure Policy JSON via New-GuestConfigurationPolicy
#      with a readable display name/description for humans:
#        - Local Policies\Security Options -> Network security: Do not store LAN Manager hash value on next password change = Enabled
# Load repository config
$configPath = Find-RepositoryConfig -StartDirectory $packageRoot
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json


# Policy display identifier: optional prefix + BaseControlId (human-readable only).
$policyDisplayPrefix = $config.ControlIdPolicyPrefix
$policyDisplayId = if ($policyDisplayPrefix) { $policyDisplayPrefix + $baseControlId } else { $packageName }
if (-not $config.OutputPaths) {
  throw "OutputPaths missing in packages/machine-configuration.config.json."
}

# Derive repo root from config location: <repoRoot>\packages\machine-configuration.config.json
$repoRoot = Split-Path -Path (Split-Path -Path $configPath -Parent) -Parent

# Apply defaults from config if parameters are not provided
if (-not $PolicyMode) {
  if ($config.PolicyMode) {
    $PolicyMode = $config.PolicyMode
  } else {
    $PolicyMode = "ApplyAndAutoCorrect"
  }
}

if (-not $ContentUriBase) {
  $ContentUriBase = $config.ContentUriBase
}

if (-not $UserAssignedIdentityResourceId) {
  $UserAssignedIdentityResourceId = $config.RequiredUamiResourceId
}

# Resolve output paths (never inside the package folder)
$packageZipOutputRoot = Join-Path $repoRoot $config.OutputPaths.PackageZipOutputRoot
$policyOutputRoot     = Join-Path $repoRoot $config.OutputPaths.PolicyOutputRoot
$mofOutputRoot        = Join-Path $repoRoot $config.OutputPaths.MofOutputRoot

$perPackageMode = $config.OutputPaths.PerPackageOutputMode
if (-not $perPackageMode) { $perPackageMode = "byControlId" }

switch ($perPackageMode) {
  "byPackageFolder" { $outFolder = $packageFolderName }
  default           { $outFolder = $controlId }
}

$packageZipOutputPath = Join-Path $packageZipOutputRoot $outFolder
$policyOutputPath     = Join-Path $policyOutputRoot     $outFolder
$mofOutputPath         = Join-Path $mofOutputRoot        $outFolder

New-Item -Path $packageZipOutputPath -ItemType Directory -Force | Out-Null
New-Item -Path $policyOutputPath     -ItemType Directory -Force | Out-Null
New-Item -Path $mofOutputPath        -ItemType Directory -Force | Out-Null

$expectedZipPath = Join-Path $packageZipOutputPath ("{0}.zip" -f $packageName)
if ((Test-Path $expectedZipPath) -and (-not $ForceRebuild)) {
  Write-Host ("Package ZIP already exists; skipping build: {0}" -f $expectedZipPath) -ForegroundColor Yellow
  return
}

# Authoring-time prerequisites (modules must exist on the authoring machine so they can be shipped in the package ZIP)
$requiredDscResourceModules = @("PSDscResources")
foreach ($moduleName in $requiredDscResourceModules) {
  if (-not (Get-Module -ListAvailable -Name $moduleName)) {
    throw ("Required DSC resource module '{0}' not found on authoring machine. Install it and retry." -f $moduleName)
  }
}

if (-not (Get-Module -ListAvailable -Name GuestConfiguration)) {
  throw "PowerShell module 'GuestConfiguration' is required. Install it first: Install-Module GuestConfiguration -Force"
}

if (-not (Get-Module -ListAvailable -Name PSDesiredStateConfiguration)) {
  throw "PowerShell module 'PSDesiredStateConfiguration' is required to compile DSC configurations. Install it first: Install-Module PSDesiredStateConfiguration -RequiredVersion 2.0.7 -Force"
}

Import-Module -Name PSDesiredStateConfiguration -ErrorAction Stop
Import-Module -Name GuestConfiguration -ErrorAction Stop

# Load the DSC configuration definition
$configurationScriptPath = Join-Path $packageRoot "Configuration.ps1"
if (-not (Test-Path $configurationScriptPath)) {
  throw ("Configuration.ps1 not found: {0}" -f $configurationScriptPath)
}
. $configurationScriptPath

# Compile MOF
& SECO_008_Network_security_Do_not_store_LAN_Manager_hash_valu -OutputPath $mofOutputPath

# DSC outputs node MOFs directly into the -OutputPath directory (for example: "<OutputPath>\localhost.mof").
# Some patterns also create a nested folder for the configuration name. Handle both to be robust.
$mofCandidatePaths = @(
  (Join-Path $mofOutputPath "localhost.mof"),
  (Join-Path (Join-Path $mofOutputPath "SECO_008_Network_security_Do_not_store_LAN_Manager_hash_valu") "localhost.mof")
)

$mofFilePath = $mofCandidatePaths | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $mofFilePath) {
  $found = Get-ChildItem -Path $mofOutputPath -Recurse -Filter "localhost.mof" -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($found) {
    $mofFilePath = $found.FullName
  }
}

if (-not $mofFilePath) {
  throw ("MOF file not found under output path: {0}" -f $mofOutputPath)
}
# Create Machine Configuration package ZIP
if ((Test-Path $expectedZipPath) -and $ForceRebuild) {
  Remove-Item -Path $expectedZipPath -Force
}

New-GuestConfigurationPackage `
  -Name $packageName `
  -Configuration $mofFilePath `
  -Type $PackageType `
  -Path $packageZipOutputPath | Out-Null

if (-not (Test-Path $expectedZipPath)) {
  throw ("Package ZIP not found at expected path: {0}" -f $expectedZipPath)
}

# Optional: generate the baseline Azure Policy definition JSON (New-GuestConfigurationPolicy)
$placeholdersPresent = $false
if (-not $ContentUriBase -or ($ContentUriBase -like "*<storageaccount>*")) { $placeholdersPresent = $true }
if (-not $UserAssignedIdentityResourceId -or ($UserAssignedIdentityResourceId -like "*/subscriptions/<sub>*")) { $placeholdersPresent = $true }

if ($placeholdersPresent) {
  Write-Warning "Skipping baseline policy generation because ContentUriBase and/or RequiredUamiResourceId are not configured (still placeholders)."
  Write-Warning "You can still build and upload the ZIP. Set values in packages/machine-configuration.config.json and rerun this build to generate baseline policies."
} else {
  $contentUri = ("{0}/{1}.zip" -f $ContentUriBase.TrimEnd("/"), $controlId)
  $policyId = (New-Guid).Guid

  # Capture existing JSON files so we can identify which one(s) New-GuestConfigurationPolicy created.
  $policyJsonBefore = @()
  if (Test-Path $policyOutputPath) {
    $policyJsonBefore = Get-ChildItem -Path $policyOutputPath -Filter "*.json" -File -ErrorAction SilentlyContinue |
      Select-Object -ExpandProperty FullName
  }

  New-GuestConfigurationPolicy `
    -PolicyId $policyId `
    -ContentUri $contentUri `
    -DisplayName ("{0} - {1} (Machine Configuration)" -f $policyDisplayId, $settingTitle) `
    -Description ("Applies Windows Server hardening setting: {0} -> {1} = {2}." -f $settingPath, $settingTitle, $settingSuggestedValue) `
    -Path $policyOutputPath `
    -Platform Windows `
    -PolicyVersion $packageVersion `
    -Mode $PolicyMode `
    -LocalContentPath $expectedZipPath `
    -ManagedIdentityResourceId $UserAssignedIdentityResourceId `
    -ExcludeArcMachines | Out-Null

  # Azure Portal note:
  # - When you paste JSON into the Portal "JSON" editor for a policy definition, the Portal expects the *properties object*
  #   (displayName/mode/metadata/parameters/policyRule) and wraps it in "properties" itself.
  # - New-GuestConfigurationPolicy writes a full policy definition JSON (with an outer "properties" wrapper).
  # - Therefore we also emit a *.portal.json variant that contains only the inner properties object.
  $policyJsonAfter = Get-ChildItem -Path $policyOutputPath -Filter "*.json" -File -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName
  $createdPolicyJson = $policyJsonAfter | Where-Object { $policyJsonBefore -notcontains $_ }
  if (-not $createdPolicyJson) {
    # Fallback: take the newest JSON in the output folder
    $createdPolicyJson = @(Get-ChildItem -Path $policyOutputPath -Filter "*.json" -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1 | Select-Object -ExpandProperty FullName)
  }

  foreach ($jsonPath in $createdPolicyJson) {
    try {
      $policyObject = Get-Content -Path $jsonPath -Raw | ConvertFrom-Json -Depth 100
      $propertiesObject = if ($policyObject.PSObject.Properties.Name -contains "properties") { $policyObject.properties } else { $policyObject }
      $portalPath = ($jsonPath -replace "\.json$", ".portal.json")
      ($propertiesObject | ConvertTo-Json -Depth 100) | Set-Content -Path $portalPath -Encoding UTF8
    } catch {
      Write-Warning ("Failed to create portal-friendly JSON variant for: {0}. Error: {1}" -f $jsonPath, $_.Exception.Message)
    }
  }
}

Write-Host "Build completed." -ForegroundColor Green
Write-Host ("MOF: {0}" -f $mofFilePath)
Write-Host ("ZIP: {0}" -f $expectedZipPath)
Write-Host ("Policy output folder: {0}" -f $policyOutputPath)