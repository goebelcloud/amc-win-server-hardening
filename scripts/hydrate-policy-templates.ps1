<#
.SYNOPSIS
  Hydrate enhanced Azure Policy JSON for all packages.

.DESCRIPTION
  Iterates all package folders under .\packages\<ControlId>\ and invokes each package's hydrate-policy.ps1.
  The per-package hydrate script renders an enhanced DeployIfNotExists policy JSON

  Note: ControlIdPolicyPrefix is used only for Azure Policy displayName. by replacing placeholders in:
    policy/deployIfNotExists.enhanced.sample.json

  The hydrated policy output is written to the configured policy output folder (never into the package folder).

  Defaults are read from:
    .\packages\machine-configuration.config.json

.NOTES
  File: hydrate-policy-templates.ps1
  Version: 1.0.0
#>

[CmdletBinding()]
param(
  [Parameter(Mandatory=$false)]
  [string]$PackagesRootPath,

  # Optional overrides (defaults come from packages/machine-configuration.config.json)
  [Parameter(Mandatory=$false)]
  [string]$ContentUriBase,

  [Parameter(Mandatory=$false)]
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

$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$repoRoot   = Split-Path -Path $scriptRoot -Parent

if (-not $PackagesRootPath) {
  $PackagesRootPath = Join-Path $repoRoot "packages"
}

$configPath = Find-RepositoryConfig -StartDirectory $PackagesRootPath
$config     = Get-Content -Path $configPath -Raw | ConvertFrom-Json
if (-not $ContentUriBase) { $ContentUriBase = $config.ContentUriBase }
if (-not $RequiredUamiResourceId) { $RequiredUamiResourceId = $config.RequiredUamiResourceId }

if (-not $ContentUriBase -or $ContentUriBase -like "*<storageaccount>*") {
  throw "ContentUriBase is not set. Update packages/machine-configuration.config.json (ContentUriBase) or pass -ContentUriBase."
}
if (-not $RequiredUamiResourceId -or $RequiredUamiResourceId -like "*/subscriptions/<sub>*") {
  throw "RequiredUamiResourceId is not set. Update packages/machine-configuration.config.json (RequiredUamiResourceId) or pass -RequiredUamiResourceId."
}

$packagesRootFullPath = (Resolve-Path $PackagesRootPath).Path
Write-Host ("Hydrating policies for packages under: {0}" -f $packagesRootFullPath) -ForegroundColor Cyan

$packageFolders = Get-ChildItem -Path $packagesRootFullPath -Directory |
  Where-Object { Test-Path (Join-Path $_.FullName "hydrate-policy.ps1") } |
  Sort-Object Name

foreach ($pkg in $packageFolders) {
  $hydrateScript = Join-Path $pkg.FullName "hydrate-policy.ps1"
  if (-not (Test-Path $hydrateScript)) {
    Write-Warning ("Skipping {0}: hydrate-policy.ps1 not found." -f $pkg.Name)
    continue
  }

  try {
    & $hydrateScript -ConfigPath $configPath -ContentUriBase $ContentUriBase -RequiredUamiResourceId $RequiredUamiResourceId
  }
  catch {
    Write-Warning ("Failed to hydrate {0}: {1}" -f $pkg.Name, $_.Exception.Message)
  }
}

Write-Host "Done." -ForegroundColor Green
