<#
.SYNOPSIS
  Validate built Machine Configuration package ZIPs locally (no Azure required).

.DESCRIPTION
  For each package folder under:
    .\packages\<ControlId>\
  this script locates the expected ZIP in the configured output folder and runs a local package validation.

  Validation uses the GuestConfiguration module cmdlet:
    Get-GuestConfigurationPackageComplianceStatus

  IMPORTANT:
  - This script assumes packages were built already.
  - ControlIdPolicyPrefix is NOT applied here. ControlIdPolicyPrefix is only used when generating Azure Policy display names.

.NOTES
  File: test-all-packages.ps1
  Version: 1.2.0
#>

[CmdletBinding()]
param(
  # Optional override of repo root (defaults to script parent\..)
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Finds the nearest 'packages/machine-configuration.config.json' by walking up the directory tree.
# This ensures we always read the same OutputPaths used during build.

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

  throw ("Could not find packages\machine-configuration.config.json by searching up from: {0}" -f $StartDirectory)
}

if (-not $RepositoryRoot) {
  $scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
  $RepositoryRoot = Split-Path $scriptRoot -Parent
}

$packagesRoot = Join-Path $RepositoryRoot "packages"

$configPath = Find-RepositoryConfig -StartDirectory $packagesRoot
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

if (-not $config.OutputPaths) {
  throw "OutputPaths missing in packages\machine-configuration.config.json."
}

$zipRoot = Join-Path $RepositoryRoot $config.OutputPaths.PackageZipOutputRoot
$perPackageMode = $config.OutputPaths.PerPackageOutputMode

Write-Host ("Repo root:     {0}" -f $RepositoryRoot)
Write-Host ("Packages root: {0}" -f $packagesRoot)
Write-Host ("ZIP output:    {0}" -f $zipRoot)
Write-Host ("Mode:          {0}" -f $perPackageMode)

if (-not (Get-Module -ListAvailable -Name "GuestConfiguration")) {
  throw "GuestConfiguration module not found. Run authoring-workstation\install-required-modules.ps1 on the authoring machine."
}

# Package discovery:
# We treat any directory that contains a build.ps1 as a package folder.
# The folder name is the ControlId (for example: win-server-ACCT-001).

$packageFolders = Get-ChildItem -Path $packagesRoot -Directory |
  Where-Object { Test-Path (Join-Path $_.FullName "build.ps1") }

$failed = 0

# Validation loop:
# This performs a local 'package compliance evaluation' using the GuestConfiguration module.
# It validates that the ZIP is structurally correct and that the compiled MOF/resources are usable.
# Azure is not required for this step; it's a fast authoring-time sanity check.

foreach ($pkg in $packageFolders) {
  $folderName = $pkg.Name
  $controlId = ($folderName -split "__")[0]

  $outFolder = if ($perPackageMode -eq "byPackageFolder") { $folderName } else { $controlId }
  $zipPath = Join-Path (Join-Path $zipRoot $outFolder) ("{0}.zip" -f $controlId)

  if (-not (Test-Path $zipPath)) {
    Write-Warning ("Missing ZIP for {0}: {1}" -f $folderName, $zipPath)
    $failed++
    continue
  }

  Write-Host ("TEST  {0}" -f $folderName) -ForegroundColor Cyan
  try {
    $status = Get-GuestConfigurationPackageComplianceStatus -Path $zipPath
    # Some versions return a single object, others return a list – just print a compact summary.
    $status | Select-Object -Property PackageName, Version, Status, Reasons | Format-List | Out-String | Write-Host
  } catch {
    Write-Error ("FAILED {0}: {1}" -f $folderName, $_.Exception.Message)
    $failed++
  }
}

if ($failed -gt 0) {
  throw ("Local package validation failed for {0} package(s)." -f $failed)
}

Write-Host "All package ZIPs validated locally." -ForegroundColor Green
