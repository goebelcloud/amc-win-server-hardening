# Terraform deployment of hydrated Machine Configuration policies

This repository supports Terraform-based deployment of Azure Policy definitions and assignments for Azure Machine Configuration (Guest Configuration).

## Key design decision: what is a policy parameter vs. what must be injected

### Azure Policy parameters (assignment-time)
These are expressed as **Azure Policy parameters** in the policy JSON and can be supplied by Terraform at policy assignment time:

- `effect`  
  - Allowed: `DeployIfNotExists`, `Disabled`
- `assignmentType` (Machine Configuration behavior)  
  - Allowed: `Audit`, `ApplyAndMonitor`, `ApplyAndAutoCorrect`
- (Enhanced policies only) `requiredUserAssignedIdentityResourceId`  
  - Used to check the VM has the expected UAMI attached

### Values that must be injected (definition-time)
The following values are required to be **concrete** inside the policy JSON so Machine Configuration can download and validate the package:

- `contentUri`
- `contentHash` (SHA256 of the package ZIP)
- `contentManagedIdentity` (UAMI resourceId used to download the package)

These are not implemented as Azure Policy parameters in this repo. Instead, they are populated by the hydrate scripts.

## Workflow overview (Azure DevOps pipeline friendly)

### Stage A — Build packages and upload ZIPs
1. On the authoring workstation, build packages:
   ```powershell
   .\scripts\build-all.ps1
   ```
2. Upload the ZIP outputs from your configured output folder (see `packages/machine-configuration.config.json`) to your storage location.

### Stage B — Hydrate policy JSON (inject contentUri/contentHash/UAMI)
1. Set these values in `packages/machine-configuration.config.json`:
   - `ContentUriBase`
   - `RequiredUamiResourceId`
2. Hydrate all enhanced policies:
   ```powershell
   .\scripts\hydrate-policy-templates.ps1
   ```
   This produces **ready-to-import** JSON files under the configured policy output folder.

### Stage C — Terraform deploy
Terraform should:
- create/update **policy definitions** using the hydrated JSON files from the output folder
- create policy assignments and pass only the policy parameters (`effect`, `assignmentType`, and for enhanced policies `requiredUserAssignedIdentityResourceId`)

## Terraform patterns (recommended)

### 1) Treat hydrated policy JSON as build artifacts
In Azure DevOps:
- publish the hydrated policy JSON folder as a pipeline artifact
- in the Terraform stage, download the artifact and point Terraform at the JSON files on disk

### 2) Use policy assignment parameters for effect + assignmentType
Example (conceptual):
- `effect = "DeployIfNotExists"`
- `assignmentType = "ApplyAndAutoCorrect"`
- `requiredUserAssignedIdentityResourceId = <uamiResourceId>`

This keeps the policy definition stable while allowing per-environment behavior changes via Terraform parameters.

## Notes
- This repo keeps descriptive text in `displayName` and `description` for humans.
- Scoping remains **Windows Server only** via `imageOffer` + `imageSKU` in enhanced policies.
