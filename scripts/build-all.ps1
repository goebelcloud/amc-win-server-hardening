<#
.SYNOPSIS
  Batch-build all Machine Configuration packages in this repository.

.DESCRIPTION
  This script finds every package folder that contains build.ps1, optionally filters
  by package-folder prefix, runs the package-local build script, and then refreshes
  the runtime package catalog.
#>

[CmdletBinding()]
param(
  [Parameter()]
  [switch]$ForceRebuild,

  [Parameter()]
  [string]$PackageFolderPrefix
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
$packagesRoot = Join-Path -Path $repositoryRoot -ChildPath 'packages'

$helperPath = Find-PackageHelperScript -StartDirectory $packagesRoot
. $helperPath
$configPath = Find-RepositoryConfig -StartDirectory $packagesRoot

# Discover all package folders that contain a build script.
$packageDirectories = Get-ChildItem -Path $packagesRoot -Directory |
  Where-Object { Test-Path -Path (Join-Path -Path $_.FullName -ChildPath 'build.ps1') } |
  Sort-Object -Property Name

if ($PackageFolderPrefix) {
  $packageDirectories = $packageDirectories | Where-Object { $_.Name.StartsWith($PackageFolderPrefix) }
}

# Run each package-local build script with the requested flags.
foreach ($packageDirectory in $packageDirectories) {
  $buildScriptPath = Join-Path -Path $packageDirectory.FullName -ChildPath 'build.ps1'
  Write-Host -Object ('BUILD {0}' -f $packageDirectory.Name) -ForegroundColor Cyan

  if ($ForceRebuild) {
    & $buildScriptPath -ForceRebuild
  }
  else {
    & $buildScriptPath
  }
}

# Refresh the runtime catalog once more at the end of the batch run.
$catalogPath = Update-PackageCatalog -ConfigPath $configPath
Write-Host -Object ('Updated runtime package catalog: {0}' -f $catalogPath) -ForegroundColor Green
