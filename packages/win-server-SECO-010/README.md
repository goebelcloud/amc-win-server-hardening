# win-server-SECO-010 — Network security: Minimum session security for NTLM SSP based (including secure RPC) clients

**Version:** 1.0.0  
**Purpose:** Enforce the following setting via Azure Machine Configuration (DSC).  
- **Setting path:** `Local Policies\Security Options`
- **Setting:** `Network security: Minimum session security for NTLM SSP based (including secure RPC) clients`
- **Suggested value:** `Require NTLMv2 session security; Require 128-bit encryption`
- **Impact:** `Low`

## Why this matters
Hardens NTLM session protection (signing/encryption) to reduce MITM and downgrade risk.

## What this package changes
- Registry: `HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0\NtlmMinClientSec` (DWord) = `537395200`

## How to evaluate the setting (built-in OS tools)
**Registry check(s)**
```powershell
reg query "HKLM\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0" /v NtlmMinClientSec
```

## Manual remediation (built-in OS tools)
You can remediate manually using:
- `secpol.msc` → `Local Policies\Security Options` → `Network security: Minimum session security for NTLM SSP based (including secure RPC) clients`  
- or direct registry tooling (`reg add`) if you manage the setting that way.

## Machine Configuration prerequisites (expected on target VMs)
These packages assume the VM is prepared for Azure Machine Configuration:
- **System-assigned managed identity enabled**  
- **Machine Configuration extension** installed: Publisher `Microsoft.GuestConfiguration`, Type `ConfigurationforWindows`, Name `AzurePolicyforWindows`  
- **Required user-assigned managed identity (UAMI)** attached to the VM (used via `contentManagedIdentity`)

## DSC configuration
- Configuration name: `SECO_010_Network_security_Minimum_session_security_for_NTLM_`
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
CIS Microsoft Windows Server 2016 Benchmark v4.0.0 — Topic area: Security Options; search for: "Network security: Minimum session security for NTLM SSP based (including secure RPC) clients".
CIS Microsoft Windows Server 2016 STIG Benchmark v3.0.0 — Topic area: Security Options; search for: "Network security: Minimum session security for NTLM SSP based (including secure RPC) clients".
WS2019:
CIS Microsoft Windows Server 2019 STIG Benchmark v4.0.0 — Topic area: Security Options; search for: "Network security: Minimum session security for NTLM SSP based (including secure RPC) clients".
WS2022:
CIS Microsoft Windows Server 2022 Benchmark v4.0.0 — Topic area: Security Options; search for: "Network security: Minimum session security for NTLM SSP based (including secure RPC) clients".
CIS Microsoft Windows Server 2022 STIG Benchmark v3.0.0 — Topic area: Security Options; search for: "Network security: Minimum session security for NTLM SSP based (including secure RPC) clients".
WS2025:
CIS Microsoft Windows Server 2025 Stand-alone v1.0.0 — Topic area: Security Options; search for: "Network security: Minimum session security for NTLM SSP based (including secure RPC) clients".

**CIS chapter IDs:** TBD (see CIS PDFs / CIS STIG docs)

## Sources
- MS baseline mapping (Windows Server 2016/2019/2022):
  Azure Policy guest configuration baseline for Windows (Server 2016/2019/2022) — search for: Network security: Minimum session security for NTLM SSP based (including secure RPC) clients
- MS baseline mapping (Windows Server 2025):
  Azure Policy guest configuration baseline for Windows Server 2025 — search for: Network security: Minimum session security for NTLM SSP based (including secure RPC) clients
- Machine Configuration package authoring (`New-GuestConfigurationPackage`):
  https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/develop-custom-package/2-create-package
- Machine Configuration policy authoring (`New-GuestConfigurationPolicy`):
  https://learn.microsoft.com/en-us/azure/governance/machine-configuration/how-to/create-policy-definition
