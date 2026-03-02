<#
.SYNOPSIS
  Installs PowerShell modules required to build Azure Machine Configuration (Guest Configuration) packages.

.DESCRIPTION
  This repository builds Machine Configuration packages using:
    - GuestConfiguration (authoring module)
    - PSDesiredStateConfiguration (DSC engine / configuration compilation)
    - PSDscResources (common DSC resources used by most packages)
    - SecurityPolicyDsc (DSC Community module used by the AccountPolicy packages)

  Microsoft guidance for Windows authoring environments recommends using
  PSDesiredStateConfiguration version 2.0.7 (stable) when compiling Windows configurations.

  Run in a PowerShell session on the build workstation (Windows recommended).

.PARAMETER Force
  Reinstall modules even if already present.

.PARAMETER Scope
  Installation scope for Install-Module (CurrentUser or AllUsers).

.NOTES
  File: install-required-modules.ps1
  Version: 1.2.0
  Repo: Azure Machine Configuration package authoring (Windows VMs)
#>

[CmdletBinding()]
param(
  [switch]$Force,

  [ValidateSet("CurrentUser","AllUsers")]
  [string]$Scope = "CurrentUser"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Determine Windows vs non-Windows reliably (Windows PowerShell 5.1 doesn't define $IsWindows)
$isWindowsPlatform = $false
if ($env:OS -eq "Windows_NT") { $isWindowsPlatform = $true }
elseif (Get-Variable -Name IsWindows -Scope Global -ErrorAction SilentlyContinue) { $isWindowsPlatform = [bool]$IsWindows }


Write-Host "Installing required modules for Machine Configuration authoring..." -ForegroundColor Cyan
Write-Host " - Scope: $Scope" -ForegroundColor Cyan
Write-Host " - Force: $Force" -ForegroundColor Cyan

# Ensure TLS 1.2 for older environments
try { [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 } catch {}

# Ensure NuGet provider exists
if (-not (Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue)) {
  Install-PackageProvider -Name NuGet -Force -Scope $Scope | Out-Null
}

# Required modules
$requiredModules = @(
  @{ Name = "GuestConfiguration"; RequiredVersion = $null; AllowPrerelease = $false }
  @{ Name = "PSDesiredStateConfiguration"; RequiredVersion = $null; AllowPrerelease = $false }
  @{ Name = "PSDscResources"; RequiredVersion = $null; AllowPrerelease = $false }
  @{ Name = "SecurityPolicyDsc"; RequiredVersion = "2.10.0.0"; AllowPrerelease = $false }
)

# On Windows, Microsoft recommends PSDesiredStateConfiguration 2.0.7 for compiling Windows configs.
if ($isWindowsPlatform) {
  ($requiredModules | Where-Object { $_.Name -eq "PSDesiredStateConfiguration" }).RequiredVersion = "2.0.7"
} else {
  # Non-Windows authoring is possible, but these packages target Windows VMs.
  # Use prerelease DSC v3 if someone insists on building on Linux/macOS.
  ($requiredModules | Where-Object { $_.Name -eq "PSDesiredStateConfiguration" }).RequiredVersion = "3.0.0-beta1"
  ($requiredModules | Where-Object { $_.Name -eq "PSDesiredStateConfiguration" }).AllowPrerelease = $true
}

foreach ($module in $requiredModules) {
  $name = $module.Name
  $requiredVersion = $module.RequiredVersion
  $allowPrerelease = [bool]$module.AllowPrerelease

  $installed = Get-Module -ListAvailable -Name $name | Sort-Object Version -Descending | Select-Object -First 1
  $alreadyOk = $false

  if ($installed) {
    if ($requiredVersion) {
      if ($installed.Version -eq [version]$requiredVersion) { $alreadyOk = $true }
    } else {
      $alreadyOk = $true
    }
  }

  if ($alreadyOk -and (-not $Force)) {
    Write-Host " - $name already installed ($($installed.Version)). Skipping." -ForegroundColor Yellow
    continue
  }

  if ($requiredVersion) {
    Write-Host " - Installing $name (RequiredVersion $requiredVersion)..." -ForegroundColor Green
    Install-Module -Name $name -RequiredVersion $requiredVersion -Scope $Scope -Force:$Force -AllowClobber -AllowPrerelease:$allowPrerelease
  } else {
    Write-Host " - Installing $name..." -ForegroundColor Green
    Install-Module -Name $name -Scope $Scope -Force:$Force -AllowClobber -AllowPrerelease:$allowPrerelease
  }
}

# Import and sanity-check core commands
Import-Module -Name GuestConfiguration -ErrorAction Stop
Import-Module -Name PSDesiredStateConfiguration -ErrorAction Stop

$requiredCommands = @(
  "New-GuestConfigurationPackage",
  "New-GuestConfigurationPolicy"
)

foreach ($cmd in $requiredCommands) {
  if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
    throw "Required command not found after installation: $cmd"
  }
}

Write-Host "Module installation and sanity-check completed successfully." -ForegroundColor Cyan