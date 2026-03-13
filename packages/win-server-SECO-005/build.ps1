<#
.SYNOPSIS
  Build this Machine Configuration package.

.DESCRIPTION
  This script compiles Configuration.ps1 to a MOF file and then creates the
  Guest Configuration ZIP in the central output folder configured in
  packages/machine-configuration.config.json.

  After the build, the script synchronizes:
    - the package-local policy-metadata.json
    - the runtime package catalog under packages/package-catalog.json
#>

[CmdletBinding()]
param(
  [Parameter()]
  [ValidateSet('Audit', 'AuditAndSet')]
  [string]$PackageType,

  [Parameter()]
  [switch]$ForceRebuild
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

function Get-ConfigurationNameFromFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )

  $fileContent = Get-Content -Path $Path -Raw
  $configurationMatch = [regex]::Match($fileContent, '(?m)^\s*Configuration\s+([A-Za-z_][A-Za-z0-9_]*)')
  if (-not $configurationMatch.Success) {
    throw ('Unable to discover DSC configuration name in {0}' -f $Path)
  }

  return $configurationMatch.Groups[1].Value
}

# Resolve the package root and import the shared metadata helpers.
$packageRoot = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$helperPath = Find-PackageHelperScript -StartDirectory $packageRoot
. $helperPath

# Read package-local metadata first so default behavior can follow the package definition.
$packageName = Split-Path -Path $packageRoot -Leaf
$metadataPath = Join-Path -Path $packageRoot -ChildPath 'policy-metadata.json'
if (-not (Test-Path -Path $metadataPath)) {
  throw ('policy-metadata.json not found: {0}' -f $metadataPath)
}

$metadata = Read-JsonFileOrdered -Path $metadataPath
$controlId = [string]$metadata.controlId

if (-not $PackageType) {
  if ([string]$metadata.assignmentTypeDefault -eq 'Audit') {
    $PackageType = 'Audit'
  }
  else {
    $PackageType = 'AuditAndSet'
  }
}

# Resolve central output locations from the repository configuration.
$configPath = Find-RepositoryConfig -StartDirectory $packageRoot
$config = Read-JsonFileOrdered -Path $configPath
if (-not $config.OutputPaths) {
  throw 'OutputPaths missing in packages/machine-configuration.config.json.'
}

$repositoryRoot = Split-Path -Path (Split-Path -Path $configPath -Parent) -Parent
$zipRoot = Join-Path -Path $repositoryRoot -ChildPath $config.OutputPaths.PackageZipOutputRoot
$mofRoot = Join-Path -Path $repositoryRoot -ChildPath $config.OutputPaths.MofOutputRoot

$perPackageOutputMode = [string]$config.OutputPaths.PerPackageOutputMode
if (-not $perPackageOutputMode) {
  $perPackageOutputMode = 'byControlId'
}

$outputFolderName = if ($perPackageOutputMode -eq 'byPackageFolder') { $packageName } else { $controlId }
$zipOutputPath = Join-Path -Path $zipRoot -ChildPath $outputFolderName
$mofOutputPath = Join-Path -Path $mofRoot -ChildPath $outputFolderName

New-Item -ItemType Directory -Path $zipOutputPath -Force | Out-Null
New-Item -ItemType Directory -Path $mofOutputPath -Force | Out-Null

$expectedZipPath = Join-Path -Path $zipOutputPath -ChildPath ('{0}.zip' -f $packageName)

# Skip rebuilds when a ZIP already exists unless the caller explicitly forces a rebuild.
if ((Test-Path -Path $expectedZipPath) -and (-not $ForceRebuild)) {
  $null = Sync-PackageMetadata -PackageRoot $packageRoot -ConfigPath $configPath
  $catalogPath = Update-PackageCatalog -ConfigPath $configPath
  Write-Host -Object ('Package ZIP already exists; skipped rebuild and refreshed metadata: {0}' -f $expectedZipPath) -ForegroundColor Yellow
  Write-Host -Object ('Updated package catalog: {0}' -f $catalogPath) -ForegroundColor Green
  return
}

# Validate that the authoring machine has the required modules.
if (-not (Get-Module -ListAvailable -Name 'GuestConfiguration')) {
  throw "PowerShell module 'GuestConfiguration' is required. Install it on the authoring machine first."
}
if (-not (Get-Module -ListAvailable -Name 'PSDesiredStateConfiguration')) {
  throw "PowerShell module 'PSDesiredStateConfiguration' is required. Install it on the authoring machine first."
}

Import-Module -Name GuestConfiguration -ErrorAction Stop
Import-Module -Name PSDesiredStateConfiguration -ErrorAction Stop

# Load the package configuration script and compile it to MOF.
$configurationScriptPath = Join-Path -Path $packageRoot -ChildPath 'Configuration.ps1'
if (-not (Test-Path -Path $configurationScriptPath)) {
  throw ('Configuration.ps1 not found: {0}' -f $configurationScriptPath)
}

$configurationName = Get-ConfigurationNameFromFile -Path $configurationScriptPath
. $configurationScriptPath
& $configurationName -OutputPath $mofOutputPath

# Support both direct localhost.mof output and nested configuration-name folders.
$mofCandidatePaths = @(
  (Join-Path -Path $mofOutputPath -ChildPath 'localhost.mof'),
  (Join-Path -Path (Join-Path -Path $mofOutputPath -ChildPath $configurationName) -ChildPath 'localhost.mof')
)

$mofFilePath = $mofCandidatePaths | Where-Object { Test-Path -Path $_ } | Select-Object -First 1
if (-not $mofFilePath) {
  $discoveredMofFile = Get-ChildItem -Path $mofOutputPath -Recurse -Filter 'localhost.mof' -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($discoveredMofFile) {
    $mofFilePath = $discoveredMofFile.FullName
  }
}

if (-not $mofFilePath) {
  throw ('MOF file not found under output path: {0}' -f $mofOutputPath)
}

if ((Test-Path -Path $expectedZipPath) -and $ForceRebuild) {
  Remove-Item -Path $expectedZipPath -Force
}

# Build the Guest Configuration ZIP.
New-GuestConfigurationPackage `
  -Name $packageName `
  -Configuration $mofFilePath `
  -Type $PackageType `
  -Path $zipOutputPath | Out-Null

if (-not (Test-Path -Path $expectedZipPath)) {
  throw ('Package ZIP was not created: {0}' -f $expectedZipPath)
}

# Write back metadata and refresh the runtime catalog.
$null = Sync-PackageMetadata -PackageRoot $packageRoot -ConfigPath $configPath
$catalogPath = Update-PackageCatalog -ConfigPath $configPath

Write-Host -Object ('Built package: {0}' -f $expectedZipPath) -ForegroundColor Green
Write-Host -Object ('Updated package metadata: {0}' -f $metadataPath) -ForegroundColor Green
Write-Host -Object ('Updated package catalog: {0}' -f $catalogPath) -ForegroundColor Green
