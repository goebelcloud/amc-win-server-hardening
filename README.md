# Azure Machine Configuration — Windows OS hardening (one setting per package)

This bundle contains:
- `packages/` — **50** packages (1 per hardening setting). Each package contains:
  - `Configuration.ps1` (DSC)
  - `build.ps1` (standalone build: MOF + zip + policy JSON via `New-GuestConfigurationPolicy`)
  - `README.md` (how to evaluate/remediate with built-in Windows tools)
  - `policy/` (policy templates + enhanced sample)
- `policies/` — shared policies:
  - `enforce_required_uami_to_vms.json` (modify policy to attach a UAMI)
  - `machine_configuration_prereqs_and_uami_initiative.json` (initiative: system MI + extension + required UAMI)
- `scripts/` — helper scripts:
  - `build-all.ps1` (batch build, skips existing outputs)
  - `hydrate-policy-templates.ps1` (fills placeholders in the template JSONs)
- `docs/00-index.md` — index of all step-by-step guides
- `docs/01-authoring-workstation-setup.md` — build/prepare the authoring VM
- `docs/02-build-a-package.md` — build a single package
- `docs/03-test-package-locally.md` — test a package locally (no Azure)
- `docs/04-test-with-azure-machine-configuration.md` — test with Azure Machine Configuration
- `docs/deployment-guide.md` — step-by-step deployment walkthrough
- `docs/pov-guide.md` — **PoV runbook** (Azure-only, end-to-end demo)
- `SOURCES.txt` — public sources referenced for this bundle

## Notes
- Scope: Azure Windows VMs only (not Arc).
- Control IDs used for packages/ZIPs/URIs are prefixed with `win-server-` (example: `win-server-ACCT-001`).
- `packages/machine-configuration.config.json` contains `ControlIdPolicyPrefix` which is used **only** to prefix Azure Policy **displayName** values (human-readable). It is not used for ZIP names or content URIs.
- Each package starts at version `1.0.0` by design.

## Authoring modules

Packages in this repository are authored with:
- `PSDscResources` for registry/file/script primitives (recommended for Guest Configuration scenarios).
- `SecurityPolicyDsc` for local account policy settings (password and lockout).

Install prerequisites on the authoring machine with:
```powershell
.\authoring-workstation\install-required-modules.ps1 -Scope CurrentUser
```





## Outputs

Build and hydration scripts **never write artifacts inside the package folders**.
All outputs go to the folders configured in `packages/machine-configuration.config.json` under `OutputPaths`.

Default output layout:
- `./output/mof/` — compiled MOFs
- `./output/zip/` — package ZIPs (upload these to storage)
- `./output/policy/` — baseline + enhanced policy JSON artifacts


## Policy JSON variants (Portal import)

Each package contains policy JSON files under `packages/<ControlId>/policy/`:

- `deployIfNotExists.portal.json` (non-enhanced, Portal import)
- `deployIfNotExists.enhanced.portal.json` (enhanced with identity/UAMI gating, Portal import)

The `*.sample.json` files include the full PolicyDefinition wrapper (`{ "properties": { ... } }`) and are intended for automation / hydration.