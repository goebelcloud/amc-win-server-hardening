<#
.SYNOPSIS
  Validate built Machine Configuration package ZIPs locally.

.DESCRIPTION
  This script enumerates the package folders in the repository, locates the expected
  ZIP for each package, and validates the ZIP with the GuestConfiguration module.
#>

[CmdletBinding()]
param(
  [Parameter()]
  [string]$RepositoryRoot
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Find-RepositoryConfig {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$StartDirectory
  )

  $currentDirectory = Resolve-Path -Path $StartDirectory
  while ($true) {
    $candidatePath = Join-Path -Path $currentDirectory -ChildPath 'machine-configuration.config.json'
    if (Test-Path -Path $candidatePath) {
      return $candidatePath
    }

    $parentDirectory = Split-Path -Path $currentDirectory -Parent
    if ($parentDirectory -eq $currentDirectory) { break }
    $currentDirectory = $parentDirectory
  }

  throw 'Could not find packages/machine-configuration.config.json.'
}

if (-not $RepositoryRoot) {
  $scriptRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
  $RepositoryRoot = Split-Path -Path $scriptRoot -Parent
}

$configPath = Find-RepositoryConfig -StartDirectory (Join-Path -Path $RepositoryRoot -ChildPath 'packages')
$config = Get-Content -Path $configPath -Raw | ConvertFrom-Json

$zipRoot = Join-Path -Path $RepositoryRoot -ChildPath $config.OutputPaths.PackageZipOutputRoot
$perPackageOutputMode = $config.OutputPaths.PerPackageOutputMode
if (-not $perPackageOutputMode) {
  $perPackageOutputMode = 'byControlId'
}

if (-not (Get-Module -ListAvailable -Name 'GuestConfiguration')) {
  throw 'GuestConfiguration module not found. Run authoring-workstation/install-required-modules.ps1 first.'
}

# Discover all package folders that are expected to have a build script and metadata.
$packageDirectories = Get-ChildItem -Path (Join-Path -Path $RepositoryRoot -ChildPath 'packages') -Directory |
  Where-Object { Test-Path -Path (Join-Path -Path $_.FullName -ChildPath 'build.ps1') } |
  Sort-Object -Property Name

$failedPackageCount = 0

foreach ($packageDirectory in $packageDirectories) {
  $metadata = Get-Content -Path (Join-Path -Path $packageDirectory.FullName -ChildPath 'policy-metadata.json') -Raw | ConvertFrom-Json
  $outputFolderName = if ($perPackageOutputMode -eq 'byPackageFolder') { $packageDirectory.Name } else { $metadata.controlId }
  $zipPath = Join-Path -Path (Join-Path -Path $zipRoot -ChildPath $outputFolderName) -ChildPath ('{0}.zip' -f $packageDirectory.Name)

  if (-not (Test-Path -Path $zipPath)) {
    Write-Warning ('Missing ZIP for {0}: {1}' -f $packageDirectory.Name, $zipPath)
    $failedPackageCount++
    continue
  }

  Write-Host -Object ('TEST {0}' -f $packageDirectory.Name) -ForegroundColor Cyan
  try {
    Get-GuestConfigurationPackageComplianceStatus -Path $zipPath |
      Select-Object -Property PackageName, Version, Status, Reasons |
      Format-List | Out-String | Write-Host
  }
  catch {
    Write-Error ('FAILED {0}: {1}' -f $packageDirectory.Name, $_.Exception.Message)
    $failedPackageCount++
  }
}

if ($failedPackageCount -gt 0) {
  throw ('Local package validation failed for {0} package(s).' -f $failedPackageCount)
}

Write-Host -Object 'All package ZIPs validated locally.' -ForegroundColor Green
