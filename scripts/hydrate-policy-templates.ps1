<#
.SYNOPSIS
  Hydrate Azure Policy definitions for all packages.

.DESCRIPTION
  This script discovers every package folder that contains hydrate-policy.ps1,
  runs the package-local hydration script, and then refreshes the runtime package catalog.
#>

[CmdletBinding()]
param(
  [Parameter()]
  [string]$PackagesRootPath,

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

$scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$repositoryRoot = Split-Path -Path $scriptRoot -Parent

if (-not $PackagesRootPath) {
  $PackagesRootPath = Join-Path -Path $repositoryRoot -ChildPath 'packages'
}

$helperPath = Find-PackageHelperScript -StartDirectory $PackagesRootPath
. $helperPath
$configPath = Find-RepositoryConfig -StartDirectory $PackagesRootPath

# Discover all package folders that contain a hydrate script.
$packageDirectories = Get-ChildItem -Path $PackagesRootPath -Directory |
  Where-Object { Test-Path -Path (Join-Path -Path $_.FullName -ChildPath 'hydrate-policy.ps1') } |
  Sort-Object -Property Name

# Hydrate each package using the same runtime inputs.
foreach ($packageDirectory in $packageDirectories) {
  $hydrateScriptPath = Join-Path -Path $packageDirectory.FullName -ChildPath 'hydrate-policy.ps1'
  Write-Host -Object ('HYDRATE {0}' -f $packageDirectory.Name) -ForegroundColor Cyan
  & $hydrateScriptPath -ContentUriBase $ContentUriBase -RequiredUamiResourceId $RequiredUamiResourceId
}

# Refresh the runtime catalog once more at the end of the batch run.
$catalogPath = Update-PackageCatalog -ConfigPath $configPath
Write-Host -Object ('Updated runtime package catalog: {0}' -f $catalogPath) -ForegroundColor Green
