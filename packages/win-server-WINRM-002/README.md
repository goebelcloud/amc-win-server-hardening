# win-server-WINRM-002 — Disallow Basic authentication

**Version:** 1.0.0  
**Purpose:** Enforce the following setting via Azure Machine Configuration (DSC):  
- **Setting path:** `Windows Components\Windows Remote Management (WinRM)\WinRM Service`
- **Setting:** `Disallow Basic authentication`
- **Suggested value:** `Basic = Disabled (use Kerberos/cert)`
- **Impact:** `Low/Medium`

## What this package changes
- Registry: `HKLM:\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\Auth\Basic` (DWORD) = `0`

## How to verify the setting is applied (built-in OS tools)

### GUI verification
1. Press **Win+R**, run `gpedit.msc` (Local Group Policy Editor).
2. Navigate to: **Windows Components > Windows Remote Management (WinRM) > WinRM Service**.
3. Open **Disallow Basic authentication** and confirm it is set to **Basic = Disabled (use Kerberos/cert)**.

### Command-line verification
**Registry check (PowerShell / reg.exe)**
```cmd
reg query "HKLM\SOFTWARE\Policies\Microsoft\Windows\WinRM\Service\Auth" /v Basic
```
Expected: `Basic` (DWord) = `0`.

## Machine Configuration prerequisites (expected on target VMs)
These packages assume the VM is prepared for Azure Machine Configuration:
- **System-assigned managed identity enabled** (required for Machine Configuration service authentication).  
- **Machine Configuration extension** installed: Publisher `Microsoft.GuestConfiguration`, Type `ConfigurationforWindows`, Name `AzurePolicyforWindows`.  
- **Required user-assigned managed identity (UAMI)** attached to the VM to access the private Storage account hosting packages (used via `contentManagedIdentity`).

You can enforce these prerequisites using the included policies under `../../policies/`.

## DSC Configuration
- Configuration name: `WINRM_002_Disallow_Basic_authentication`
- Source file: `Configuration.ps1`

## Build this package (standalone)

**Prereqs on your authoring/build machine**
- PowerShell 7
- Modules: `GuestConfiguration` (and its dependencies)  
  See Microsoft authoring guidance.

**Steps**
1. Open PowerShell 7 as Administrator.
2. From this package directory, run:
   ```powershell
   ./build.ps1 `
     -PackageType AuditAndSet `
     -PolicyMode ApplyAndAutoCorrect `
     -ContentUri "https://<storage>.blob.core.windows.net/<container>/win-server-WINRM-002.zip" `
     -UserAssignedIdentityResourceId "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<uami>"
   ```

Outputs are written to the folders configured in `packages/machine-configuration.config.json` (OutputPaths). Default locations:
- `./output/mof/` (compiled MOFs)
- `./output/zip/` (package ZIPs)
- `./output/policy/` (policy JSON artifacts)

## Build in batch (repo root)

From the repo root:
```powershell
./scripts/build-all.ps1 -PackageType AuditAndSet -PolicyMode ApplyAndAutoCorrect
```

The script skips packages that already have an output zip unless you add `-ForceRebuild`.

## Policy files included
- `policy/deployIfNotExists.json` — base policy template (mirrors `New-GuestConfigurationPolicy` structure; placeholders present).
- `policy/deployIfNotExists.enhanced.sample.json` — sample showing how to add prerequisite + UAMI checks.

## Sources (primary)
- Azure Policy guest configuration baseline for Windows Server 2016/2019/2022 (setting mappings):  
  https://learn.microsoft.com/en-us/azure/governance/policy/samples/guest-configuration-baseline-windows
- Azure Policy guest configuration baseline for Windows Server 2025:  
  https://learn.microsoft.com/en-us/azure/governance/policy/samples/guest-configuration-baseline-windows-server-2025
- Machine Configuration package authoring (`New-GuestConfigurationPackage`):  
  https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/develop-custom-package/2-create-package
- Machine Configuration policy authoring (`New-GuestConfigurationPolicy`):  
  https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/create-policy-definition

## Hydrate policy JSON for this package

After you built the package zip (`./output/zip/<ControlID>/<ControlID>.zip` by default; see OutputPaths) and uploaded it to storage, run:

```powershell
./hydrate-policy.ps1
```

This will create `deployIfNotExists.enhanced.json` in the configured policy output folder (default: `./output/policy/<ControlID>/deployIfNotExists.enhanced.json`) using values from the repository config file `packages/machine-configuration.config.json`.
