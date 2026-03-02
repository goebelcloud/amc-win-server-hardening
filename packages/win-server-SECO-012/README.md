# win-server-SECO-012 — Microsoft network client: Digitally sign communications (always)

**Version:** 1.0.0  
**Purpose:** Enforce the following setting via Azure Machine Configuration (DSC).  
- **Setting path:** `Local Policies\Security Options`
- **Setting:** `Microsoft network client: Digitally sign communications (always)`
- **Suggested value:** `Enabled (SMB signing required for outbound SMB client traffic)`
- **Impact:** `Medium (legacy/non-signing SMB servers)`

## Why this matters
Reduces SMB man-in-the-middle tampering by requiring SMB signing on the client; may break connections to non-signing servers.

## What this package changes
- (No registry entries parsed from Configuration.ps1. Review configuration for details.)

## How to evaluate the setting (built-in OS tools)
**Registry check(s)**
```powershell
# (No registry entries parsed from Configuration.ps1.)
```

## Manual remediation (built-in OS tools)
You can remediate manually using:
- `secpol.msc` → `Local Policies\Security Options` → `Microsoft network client: Digitally sign communications (always)`  
- or direct registry tooling (`reg add`) if you manage the setting that way.

## Machine Configuration prerequisites (expected on target VMs)
These packages assume the VM is prepared for Azure Machine Configuration:
- **System-assigned managed identity enabled**  
- **Machine Configuration extension** installed: Publisher `Microsoft.GuestConfiguration`, Type `ConfigurationforWindows`, Name `AzurePolicyforWindows`  
- **Required user-assigned managed identity (UAMI)** attached to the VM (used via `contentManagedIdentity`)

## DSC configuration
- Configuration name: `SECO_012_Microsoft_network_client_Digitally_sign_communicati`
- Source file: `Configuration.ps1`

## Build this package (standalone)
From this package directory:
```powershell
.\build.ps1
```

## Hydrate the enhanced policy JSON for this package
After uploading the built ZIP and setting `ContentUriBase` + `RequiredUamiResourceId` in `packages/machine-configuration.config.json`:
```powershell
.\hydrate-policy.ps1
```

## Policy files included
- `policy/deployIfNotExists.json` — baseline policy template
- `policy/deployIfNotExists.enhanced.sample.json` — enhanced sample with prerequisite checks + UAMI requirement + Windows Server offer/SKU scope

## CIS / benchmarks reference
WS2016:
CIS Microsoft Windows Server 2016 Benchmark v4.0.0 — Topic area: Security Options; search for: "Microsoft network client: Digitally sign communications (always)".
CIS Microsoft Windows Server 2016 STIG Benchmark v3.0.0 — Topic area: Security Options; search for: "Microsoft network client: Digitally sign communications (always)".
WS2019:
CIS Microsoft Windows Server 2019 STIG Benchmark v4.0.0 — Topic area: Security Options; search for: "Microsoft network client: Digitally sign communications (always)".
WS2022:
CIS Microsoft Windows Server 2022 Benchmark v4.0.0 — Topic area: Security Options; search for: "Microsoft network client: Digitally sign communications (always)".
CIS Microsoft Windows Server 2022 STIG Benchmark v3.0.0 — Topic area: Security Options; search for: "Microsoft network client: Digitally sign communications (always)".
WS2025:
CIS Microsoft Windows Server 2025 Stand-alone v1.0.0 — Topic area: Security Options; search for: "Microsoft network client: Digitally sign communications (always)".

**CIS chapter IDs:** TBD (see CIS PDFs / CIS STIG docs)

## Sources
- MS baseline mapping (Windows Server 2016/2019/2022):
  Azure Policy guest configuration baseline for Windows (Server 2016/2019/2022) — search for: Microsoft network client: Digitally sign communications (always)
- MS baseline mapping (Windows Server 2025):
  Azure Policy guest configuration baseline for Windows Server 2025 — search for: Microsoft network client: Digitally sign communications (always)
- Machine Configuration package authoring (`New-GuestConfigurationPackage`):
  https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/develop-custom-package/2-create-package
- Machine Configuration policy authoring (`New-GuestConfigurationPolicy`):
  https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/create-policy-definition
