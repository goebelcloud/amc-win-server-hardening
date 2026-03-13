# PoV / pilot guide

## Phase 1 — recommended default baseline
Start with the controls from the general cloud / Azure Windows Server baseline:

- `ACCT-001` to `ACCT-009`
- `AUD-001` to `AUD-006`
- `DEF-001` to `DEF-003`
- `FW-001`, `FW-002`
- `LOG-001`, `LOG-002`
- `NET-001`
- `RDP-001`, `RDP-002`
- `SECO-001` to `SECO-009`
- `UAC-001`, `UAC-002`, `UAC-003`
- `WINRM-001`, `WINRM-002`

## Phase 2 — optional / targeted testing
Add only when needed or after explicit functional approval:

- `LSA-001`
- `RDP-003`
- `SECO-010` to `SECO-016`

## No longer included in the package set
These controls were intentionally removed in this package iteration:

- `NET-002`
- `SECO-017`

## Pilot recommendation
- start with a small number of VMs in a dedicated test resource group
- start with `Audit` or `ApplyAndMonitor`
- then move in a controlled way to `ApplyAndAutoCorrect`
- always validate with the package README and Guest assignment checks
