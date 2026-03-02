# 01 — Build/prepare the authoring VM

This guide prepares a Windows authoring machine to build and validate Machine Configuration packages from this repository.

## 1. Recommended VM baseline

- Windows Server 2022 or Windows 11 (works with PowerShell 7)
- Internet access to the PowerShell Gallery (or a mirrored internal gallery)
- Git installed (or download repo ZIP)

## 2. Get the repository

```powershell
git clone <your-repo-url>
cd <repo-folder>
```

## 3. Install PowerShell 7 (recommended)

If `pwsh` is not available, install PowerShell 7 on the authoring machine.

Verify:

```powershell
pwsh -NoLogo -Command "$PSVersionTable.PSVersion"
```

## 4. Install required authoring modules

This repo includes an installer script:

```powershell
cd .\authoring-workstation
.\install-required-modules.ps1 -Scope CurrentUser
```

What this does:
- Installs required PowerShell modules to build/validate packages (DSC resources, GuestConfiguration tooling).
- These modules are required on the **authoring** machine. Packages themselves embed required resources during build.

## 5. Validate module availability

```powershell
Get-Module -ListAvailable PSDscResources, SecurityPolicyDsc, GuestConfiguration |
  Select-Object Name, Version | Format-Table -AutoSize
```

If `GuestConfiguration` is missing, the local package validation step will not work.

## 6. Configure repo settings

Open:

`packages\machine-configuration.config.json`

Important fields:
- `ContentUriBase`: your storage URL base (used when hydrating policy JSON)
- `RequiredUamiResourceId`: UAMI resource ID the VM must have
- `OutputPaths`: where build artifacts are written
- `ControlIdPolicyPrefix`: used **only** for Azure Policy `displayName`

You can build packages without Azure values, but hydration needs valid `ContentUriBase` and `RequiredUamiResourceId`.
