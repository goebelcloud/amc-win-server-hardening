<#
.SYNOPSIS
  Install PowerShell modules required to author and validate the packages in this repository.

.DESCRIPTION
  This script installs the module set expected by the package authoring workflow,
  imports the modules, and validates the DSC resources that are required by the
  package configurations in this repository.
#>

[CmdletBinding()]
param(
  [Parameter()]
  [switch]$Force,

  [Parameter()]
  [ValidateSet('CurrentUser', 'AllUsers')]
  [string]$Scope = 'CurrentUser'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Determine whether the current session is running on Windows so the correct
# PSDesiredStateConfiguration version can be chosen.
$isWindowsPlatform = $false
if ($env:OS -eq 'Windows_NT') {
  $isWindowsPlatform = $true
}
elseif (Get-Variable -Name IsWindows -Scope Global -ErrorAction SilentlyContinue) {
  $isWindowsPlatform = [bool]$IsWindows
}

# Force TLS 1.2 where possible for older PowerShell environments.
try {
  [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
}
catch {
}

# Ensure the NuGet provider exists before module installation begins.
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
  Install-PackageProvider -Name NuGet -Force -Scope $Scope | Out-Null
}

$requiredModules = @(
  @{ Name = 'GuestConfiguration';           RequiredVersion = $null;      AllowPrerelease = $false }
  @{ Name = 'PSDesiredStateConfiguration'; RequiredVersion = $null;      AllowPrerelease = $false }
  @{ Name = 'PSDscResources';              RequiredVersion = $null;      AllowPrerelease = $false }
  @{ Name = 'SecurityPolicyDsc';           RequiredVersion = '2.10.0.0'; AllowPrerelease = $false }
)

# Match PSDesiredStateConfiguration to the local platform/runtime.
if ($isWindowsPlatform) {
  ($requiredModules | Where-Object { $_.Name -eq 'PSDesiredStateConfiguration' }).RequiredVersion = '2.0.7'
}
else {
  ($requiredModules | Where-Object { $_.Name -eq 'PSDesiredStateConfiguration' }).RequiredVersion = '3.0.0-beta1'
  ($requiredModules | Where-Object { $_.Name -eq 'PSDesiredStateConfiguration' }).AllowPrerelease = $true
}

# Install missing modules or reinstall them when -Force is used.
foreach ($requiredModule in $requiredModules) {
  $moduleName = $requiredModule.Name
  $requiredVersion = $requiredModule.RequiredVersion
  $allowPrerelease = [bool]$requiredModule.AllowPrerelease

  $installedModule = Get-Module -ListAvailable -Name $moduleName | Sort-Object -Property Version -Descending | Select-Object -First 1
  $moduleAlreadySatisfiesRequirement = $false

  if ($installedModule) {
    if ($requiredVersion) {
      if ($installedModule.Version -eq [version]$requiredVersion) {
        $moduleAlreadySatisfiesRequirement = $true
      }
    }
    else {
      $moduleAlreadySatisfiesRequirement = $true
    }
  }

  if ($moduleAlreadySatisfiesRequirement -and (-not $Force)) {
    Write-Host -Object ('{0} already installed ({1}).' -f $moduleName, $installedModule.Version) -ForegroundColor Yellow
    continue
  }

  if ($requiredVersion) {
    Install-Module -Name $moduleName -RequiredVersion $requiredVersion -Scope $Scope -Force:$Force -AllowClobber -AllowPrerelease:$allowPrerelease
  }
  else {
    Install-Module -Name $moduleName -Scope $Scope -Force:$Force -AllowClobber -AllowPrerelease:$allowPrerelease
  }
}

# Import all required modules explicitly so failures are visible immediately.
Import-Module -Name GuestConfiguration -ErrorAction Stop
Import-Module -Name PSDesiredStateConfiguration -ErrorAction Stop
Import-Module -Name PSDscResources -ErrorAction Stop
Import-Module -Name SecurityPolicyDsc -ErrorAction Stop

$requiredCommands = @(
  'New-GuestConfigurationPackage',
  'Get-GuestConfigurationPackageComplianceStatus'
)

foreach ($requiredCommand in $requiredCommands) {
  if (-not (Get-Command -Name $requiredCommand -ErrorAction SilentlyContinue)) {
    throw ('Required command not found after installation: {0}' -f $requiredCommand)
  }
}

$requiredDscResources = @(
  @{ Name = 'File';                   ModuleName = 'PSDscResources' },
  @{ Name = 'Registry';               ModuleName = 'PSDscResources' },
  @{ Name = 'Script';                 ModuleName = 'PSDscResources' },
  @{ Name = 'AccountPolicy';          ModuleName = 'SecurityPolicyDsc' },
  @{ Name = 'AuditPolicySubcategory'; ModuleName = 'SecurityPolicyDsc' },
  @{ Name = 'SecurityOption';         ModuleName = 'SecurityPolicyDsc' }
)

# Validate that the DSC resources required by the package configurations are available.
foreach ($requiredResource in $requiredDscResources) {
  $discoveredResource = Get-DscResource -Name $requiredResource.Name -ErrorAction SilentlyContinue |
    Where-Object { $_.ModuleName -eq $requiredResource.ModuleName } |
    Select-Object -First 1

  if (-not $discoveredResource) {
    throw ('Required DSC resource not found after installation: {0} from module {1}' -f $requiredResource.Name, $requiredResource.ModuleName)
  }
}

Write-Host -Object 'Module installation completed successfully.' -ForegroundColor Green
