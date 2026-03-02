<#
.SYNOPSIS
  Batch-build all Machine Configuration packages in this repository.

.DESCRIPTION
  Discovers all package folders under:
    .\packages\<ControlId>\
  and invokes each package's build.ps1.

  The ControlId is the package folder name (for example: "win-server-ACCT-001").

  Build outputs are written ONLY to the locations configured in:
    .\packages\machine-configuration.config.json (OutputPaths)

  This script does not apply ControlIdPolicyPrefix; ControlIdPolicyPrefix is used only when generating Azure Policy display names.

.NOTES
  File: build-all.ps1
  Version: 1.1.0
#>

[CmdletBinding()]
param(
  # Rebuild even if a ZIP already exists in the configured output folder
  [switch]$ForceRebuild,

  # Optional: only build packages whose folder name starts with this value (example: "win-server-SECO-")
  [string]$PackageFolderPrefix
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

  throw ("Could not find packages\machine-configuration.config.json by searching up from: {0}" -f $StartDirectory)
}

# Repo context
$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$repoRoot = Split-Path $scriptRoot -Parent
$packagesRoot = Join-Path $repoRoot "packages"

$configPath = Find-RepositoryConfig -StartDirectory $packagesRoot
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

if (-not $config.OutputPaths) {
  throw "OutputPaths missing in packages\machine-configuration.config.json."
}

$zipRoot = Join-Path $repoRoot $config.OutputPaths.PackageZipOutputRoot
$perPackageMode = $config.OutputPaths.PerPackageOutputMode

Write-Host ("Repo root:     {0}" -f $repoRoot)
Write-Host ("Packages root: {0}" -f $packagesRoot)
Write-Host ("ZIP output:    {0}" -f $zipRoot)
Write-Host ("Mode:          {0}" -f $perPackageMode)

$packageFolders = Get-ChildItem -Path $packagesRoot -Directory |
  Where-Object { Test-Path (Join-Path $_.FullName "build.ps1") }

if ($PackageFolderPrefix) {
  $packageFolders = $packageFolders | Where-Object { $_.Name.StartsWith($PackageFolderPrefix) }
}

foreach ($pkg in $packageFolders) {
  $pkgPath = $pkg.FullName
  $folderName = $pkg.Name
  $controlId = ($folderName -split "__")[0]

  $outFolder = if ($perPackageMode -eq "byPackageFolder") { $folderName } else { $controlId }
  $expectedZipPath = Join-Path (Join-Path $zipRoot $outFolder) ("{0}.zip" -f $controlId)

  if ((Test-Path $expectedZipPath) -and (-not $ForceRebuild)) {
    Write-Host ("SKIP  {0} (ZIP exists)" -f $folderName) -ForegroundColor DarkGray
    continue
  }

  Write-Host ("BUILD {0}" -f $folderName) -ForegroundColor Cyan
  $buildScriptPath = Join-Path $pkgPath "build.ps1"

  if ($ForceRebuild) {
    & $buildScriptPath -ForceRebuild
  } else {
    & $buildScriptPath
  }
}
