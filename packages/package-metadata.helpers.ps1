<#
.SYNOPSIS
  Shared helper functions for package artifact metadata and the runtime package catalog.

.DESCRIPTION
  This script centralizes the logic that is reused by package-local build and hydrate scripts:
    - read and write ordered JSON documents
    - locate the repository configuration file
    - resolve package artifact paths and content hashes
    - synchronize package-local metadata
    - maintain the runtime package catalog based on package folders that actually exist
#>

Set-StrictMode -Version Latest

# Convert arbitrary JSON-derived objects into ordered PowerShell data structures.
# This keeps key ordering stable when metadata files are rewritten.
function ConvertTo-OrderedData {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    $InputObject
  )

  if ($null -eq $InputObject) { return $null }

  if ($InputObject -is [System.Collections.IDictionary]) {
    $orderedResult = [ordered]@{}
    foreach ($key in $InputObject.Keys) {
      $orderedResult[[string]$key] = ConvertTo-OrderedData -InputObject $InputObject[$key]
    }
    return $orderedResult
  }

  if (($InputObject -is [System.Collections.IEnumerable]) -and -not ($InputObject -is [string])) {
    $orderedItems = @()
    foreach ($item in $InputObject) {
      $orderedItems += ,(ConvertTo-OrderedData -InputObject $item)
    }
    return $orderedItems
  }

  if ($InputObject.PSObject -and $InputObject.PSObject.Properties.Count -gt 0) {
    $orderedResult = [ordered]@{}
    foreach ($property in $InputObject.PSObject.Properties) {
      $orderedResult[$property.Name] = ConvertTo-OrderedData -InputObject $property.Value
    }
    return $orderedResult
  }

  return $InputObject
}

# Read a JSON file and preserve key ordering.
function Read-JsonFileOrdered {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )

  if (-not (Test-Path -Path $Path)) {
    throw ("JSON file not found: {0}" -f $Path)
  }

  $jsonText = Get-Content -Path $Path -Raw
  if (-not $jsonText.Trim()) {
    return [ordered]@{}
  }

  $jsonObject = $jsonText | ConvertFrom-Json -Depth 100
  return (ConvertTo-OrderedData -InputObject $jsonObject)
}

# Write a JSON file with stable formatting.
function Write-JsonFile {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Path,

    [Parameter(Mandatory)]
    $Data
  )

  $jsonText = $Data | ConvertTo-Json -Depth 100
  Set-Content -Path $Path -Value $jsonText -Encoding UTF8
}

# Walk up the directory tree until the central repository config is found.
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

# Normalize path separators so metadata stays platform-neutral.
function ConvertTo-PortablePath {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$Path
  )

  return ($Path -replace '\\', '/')
}

function Get-PackageCatalogPath {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$ConfigPath
  )

  $packagesRoot = Split-Path -Path $ConfigPath -Parent
  return (Join-Path -Path $packagesRoot -ChildPath 'package-catalog.json')
}

# Create the empty placeholder structure used when no packages have been cataloged yet.
function New-EmptyPackageCatalogData {
  [CmdletBinding()]
  param()

  return [ordered]@{
    schemaVersion        = '1.0'
    generatedUtc         = (Get-Date).ToUniversalTime().ToString('o')
    packageCount         = 0
    artifactPresentCount = 0
    packageFolders       = @()
    controlIds           = @()
    packages             = @()
  }
}

# Resolve the expected artifact path and the values that must be written back into metadata.
function Get-PackageArtifactInfo {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$PackageRoot,

    [Parameter(Mandatory)]
    [string]$ConfigPath,

    [string]$ContentUriBaseOverride
  )

  $config = Read-JsonFileOrdered -Path $ConfigPath
  $metadataPath = Join-Path -Path $PackageRoot -ChildPath 'policy-metadata.json'
  $metadata = Read-JsonFileOrdered -Path $metadataPath
  $packageName = Split-Path -Path $PackageRoot -Leaf
  $controlId = [string]$metadata.controlId

  $perPackageOutputMode = [string]$config.OutputPaths.PerPackageOutputMode
  if (-not $perPackageOutputMode) {
    $perPackageOutputMode = 'byControlId'
  }

  $outputFolderName = if ($perPackageOutputMode -eq 'byPackageFolder') { $packageName } else { $controlId }
  $repositoryRoot = Split-Path -Path (Split-Path -Path $ConfigPath -Parent) -Parent
  $packageZipFileName = '{0}.zip' -f $packageName
  $packageZipRelativePath = ConvertTo-PortablePath -Path (Join-Path -Path (Join-Path -Path $config.OutputPaths.PackageZipOutputRoot -ChildPath $outputFolderName) -ChildPath $packageZipFileName)
  $zipPath = Join-Path -Path $repositoryRoot -ChildPath $packageZipRelativePath

  $effectiveContentUriBase = if ($ContentUriBaseOverride) { $ContentUriBaseOverride } else { [string]$config.ContentUriBase }
  $contentUri = if ($effectiveContentUriBase) {
    '{0}/{1}' -f $effectiveContentUriBase.TrimEnd('/'), $packageZipFileName
  } else {
    ''
  }

  $contentHash = ''
  $artifactPresent = $false
  if (Test-Path -Path $zipPath) {
    $contentHash = (Get-FileHash -Path $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
    $artifactPresent = $true
  }

  return [ordered]@{
    packageName            = $packageName
    controlId              = $controlId
    packageZipFileName     = $packageZipFileName
    packageZipRelativePath = $packageZipRelativePath
    zipPath                = $zipPath
    contentUri             = $contentUri
    contentHash            = $contentHash
    contentHashAlgorithm   = 'SHA256'
    artifactPresent        = $artifactPresent
  }
}

# Write the latest artifact values back into a package's policy-metadata.json.
function Sync-PackageMetadata {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$PackageRoot,

    [Parameter(Mandatory)]
    [string]$ConfigPath,

    [string]$ContentUriBaseOverride
  )

  $metadataPath = Join-Path -Path $PackageRoot -ChildPath 'policy-metadata.json'
  $metadata = Read-JsonFileOrdered -Path $metadataPath
  $artifactInfo = Get-PackageArtifactInfo -PackageRoot $PackageRoot -ConfigPath $ConfigPath -ContentUriBaseOverride $ContentUriBaseOverride

  $metadata['contentUri'] = [string]$artifactInfo.contentUri
  $metadata['contentHash'] = [string]$artifactInfo.contentHash
  $metadata['contentHashAlgorithm'] = [string]$artifactInfo.contentHashAlgorithm
  $metadata['packageZipFileName'] = [string]$artifactInfo.packageZipFileName
  $metadata['packageZipRelativePath'] = [string]$artifactInfo.packageZipRelativePath
  $metadata['artifactPresent'] = [bool]$artifactInfo.artifactPresent
  $metadata['artifactSyncUtc'] = (Get-Date).ToUniversalTime().ToString('o')

  Write-JsonFile -Path $metadataPath -Data $metadata

  return [ordered]@{
    metadataPath = $metadataPath
    artifactInfo = $artifactInfo
  }
}

# Build a single catalog entry from one package folder.
function Get-PackageCatalogEntry {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$PackageRoot
  )

  $metadataPath = Join-Path -Path $PackageRoot -ChildPath 'policy-metadata.json'
  if (-not (Test-Path -Path $metadataPath)) {
    return $null
  }

  $metadata = Read-JsonFileOrdered -Path $metadataPath
  $packageFolder = Split-Path -Path $PackageRoot -Leaf
  $catalogEntry = [ordered]@{ packageFolder = $packageFolder }
  foreach ($key in $metadata.Keys) {
    $catalogEntry[$key] = $metadata[$key]
  }

  return $catalogEntry
}

# Enumerate package folders that currently exist under /packages.
function Get-CurrentPackageCatalogEntries {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$PackagesRoot
  )

  $catalogEntries = @()

  $packageDirectories = Get-ChildItem -Path $PackagesRoot -Directory |
    Where-Object { Test-Path -Path (Join-Path -Path $_.FullName -ChildPath 'policy-metadata.json') } |
    Sort-Object -Property Name

  foreach ($packageDirectory in $packageDirectories) {
    $catalogEntry = Get-PackageCatalogEntry -PackageRoot $packageDirectory.FullName
    if ($null -ne $catalogEntry) {
      $catalogEntries += ,$catalogEntry
    }
  }

  return $catalogEntries
}

# Rebuild the runtime package catalog from the package folders that are currently present.
# Existing entries are updated, new entries are appended, and missing folders are pruned.
function Update-PackageCatalog {
  [CmdletBinding()]
  param(
    [Parameter(Mandatory)]
    [string]$ConfigPath
  )

  $packagesRoot = Split-Path -Path $ConfigPath -Parent
  $catalogPath = Get-PackageCatalogPath -ConfigPath $ConfigPath

  $existingCatalog = New-EmptyPackageCatalogData
  if (Test-Path -Path $catalogPath) {
    try {
      $candidateCatalog = Read-JsonFileOrdered -Path $catalogPath
      if ($candidateCatalog) {
        $existingCatalog = $candidateCatalog
      }
    }
    catch {
      $existingCatalog = New-EmptyPackageCatalogData
    }
  }

  $existingCatalogMap = @{}
  if ($existingCatalog.packages) {
    foreach ($existingEntry in $existingCatalog.packages) {
      if ($existingEntry.packageFolder) {
        $existingCatalogMap[[string]$existingEntry.packageFolder] = ConvertTo-OrderedData -InputObject $existingEntry
      }
    }
  }

  $currentEntries = Get-CurrentPackageCatalogEntries -PackagesRoot $packagesRoot
  $currentEntryMap = @{}
  foreach ($currentEntry in $currentEntries) {
    $currentEntryMap[[string]$currentEntry.packageFolder] = $currentEntry
  }

  foreach ($packageFolderName in @($existingCatalogMap.Keys)) {
    if (-not $currentEntryMap.ContainsKey($packageFolderName)) {
      $existingCatalogMap.Remove($packageFolderName)
    }
  }

  foreach ($packageFolderName in @($currentEntryMap.Keys)) {
    $existingCatalogMap[$packageFolderName] = $currentEntryMap[$packageFolderName]
  }

  $mergedEntries = @(
    $existingCatalogMap.GetEnumerator() |
      Sort-Object -Property Key |
      ForEach-Object { $_.Value }
  )

  $packageFolders = @()
  $controlIds = @()
  $artifactPresentCount = 0
  foreach ($mergedEntry in $mergedEntries) {
    $packageFolders += ,[string]$mergedEntry.packageFolder
    $controlIds += ,[string]$mergedEntry.controlId
    if ($mergedEntry.artifactPresent) {
      $artifactPresentCount++
    }
  }

  $catalogData = [ordered]@{
    schemaVersion        = if ($existingCatalog.schemaVersion) { [string]$existingCatalog.schemaVersion } else { '1.0' }
    generatedUtc         = (Get-Date).ToUniversalTime().ToString('o')
    packageCount         = $mergedEntries.Count
    artifactPresentCount = $artifactPresentCount
    packageFolders       = $packageFolders
    controlIds           = $controlIds
    packages             = $mergedEntries
  }

  Write-JsonFile -Path $catalogPath -Data $catalogData
  return $catalogPath
}
