# Azure Machine Configuration Hardening Packages — Refactored Cloud VM Review

This repository contains 48 Windows Server hardening packages for Azure Machine Configuration in the refactored target structure.

## Key characteristics

- Package folders use only the form `win-server-<Control-ID>`.
- Package folders do not contain generated policy files or local output artifacts.
- Azure Policy is generated only from the two central templates under `policy-templates/` plus one `policy-metadata.json` file per package.
- Each `policy-metadata.json` also stores the last synchronized artifact state (`contentUri`, `contentHash`, ZIP path, and synchronization timestamp).
- `packages/package-catalog.json` is a runtime-generated central JSON file that contains only the packages currently present in the directory.
- Only two policy variants exist:
  - `deployIfNotExists.json`
  - `deployIfNotExists.enhanced.json`
- `*.portal.json`, tag-scope variants, and publisher/tag special variants are removed.
- VM scoping uses only:
  - `Microsoft.Compute/imagePublisher`
  - `Microsoft.Compute/imageOffer`
  - `Microsoft.Compute/imageSku`
- Package numbering is ordered so that recommended controls appear first. Optional controls appear at the end of their category.
- `SECO-015` is an audit package that flags VMs where a local account uses the name `Administrator`.

## Package layout

```text
packages/
  machine-configuration.config.json
  package-catalog.json
  package-metadata.helpers.ps1
  win-server-ACCT-001/
    Configuration.ps1
    build.ps1
    hydrate-policy.ps1
    policy-metadata.json
    README.md
  ...
policy-templates/
  deployIfNotExists.template.json
  deployIfNotExists.enhanced.template.json
package_template/
  README.md
  win-server-CAT-001/
scripts/
  build-all.ps1
  hydrate-policy-templates.ps1
  test-all-packages.ps1
documentation/
  windows_server_os_hardening_suggestions_common_table_only.xlsx
docs/
  00-index.md
  01-authoring-workstation-setup.md
  02-build-a-package.md
  03-test-package-locally.md
  04-test-with-azure-machine-configuration.md
  05-terraform-policy-templates.md
  06-quality-check-summary.md
  07-monitoring-observability.md
  deployment-guide.md
  pov-guide.md
```

## Azure cloud VM grouping

### Recommended default baseline
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

### Optional / targeted testing
- `LSA-001`
- `RDP-003`
- `SECO-010` to `SECO-016`

### No longer included in the package set
- `NET-002`
- `SECO-017`

## Central configuration

`packages/machine-configuration.config.json` controls:

- `ContentUriBase`
- `RequiredUamiResourceId`
- `PolicyDisplayPrefix`
- the central output paths under `OutputPaths`

`PolicyDisplayPrefix` is used only for the Azure Policy `displayName`. It does not affect:

- package folder names
- control IDs
- ZIP file names
- `contentUri`
- Excel control IDs

## Quick start

1. Install modules on a Windows authoring VM:
   ```powershell
   pwsh ./authoring-workstation/install-required-modules.ps1
   ```
2. Build a package:
   ```powershell
   pwsh ./packages/win-server-ACCT-001/build.ps1
   ```
3. Upload the ZIP to Blob Storage.
4. Hydrate the policy files:
   ```powershell
   pwsh ./packages/win-server-ACCT-001/hydrate-policy.ps1
   ```
5. Import exactly one hydrated policy and create an assignment.
6. Always validate on three levels:
   - the Guest Configuration assignment on the VM
   - the agent / Guest Configuration log
   - the actual Windows target setting

## Additional documentation

- `docs/00-index.md`
- `docs/05-terraform-policy-templates.md`
- `docs/07-monitoring-observability.md`
- `docs/06-quality-check-summary.md`
