# PoV Guide (Azure Windows VMs only) — Terraform-managed infrastructure

This guide explains how to run a Proof of Value (PoV) using the packages in this repository **assuming all Azure infrastructure is provisioned by Terraform**.

## What Terraform must provision (out of scope for this repo)

Terraform should create/provide the following (names are examples):

- A Resource Group (or Management Group scope) for policy assignments
- A Storage Account and a private Blob container that stores Machine Configuration packages (`*.zip`)
- A **User Assigned Managed Identity (UAMI) for package access**  
  - Granted **Storage Blob Data Reader** on the Storage Account/container
  - Attached to target VMs (as required by your design)
- A **UAMI for policy remediation** (assignment identity)  
  - Used on policy assignments for `DeployIfNotExists` and `Modify` effects
  - Must have RBAC to create/modify VM extensions and guest configuration assignments

> This repo intentionally contains **no scripts that create Azure resources or upload packages**. Those actions are expected to be handled by Terraform and/or your CI/CD pipeline.

## Steps

### 1) Build all packages locally (authoring workstation)

Prerequisites:
- Windows PowerShell 5.1 or PowerShell 7.x
- Modules:
  - `GuestConfiguration`
  - `PSDscResources`

Run:

```powershell
cd .\scripts
.\build-all.ps1
```

Outputs (per package):
- `packages/<package>/output/package/<ControlID>.zip`  
- `packages/<package>/output/policy/*.json` (base policies from `New-GuestConfigurationPolicy`)

### 2) Upload the package ZIPs (handled by Terraform / pipeline)

Terraform (or your pipeline) uploads the generated `*.zip` files to the private blob container.

Record for each package:
- `contentUri` (the blob URL to the zip)
- `contentHash` (SHA256 of the zip)

### 3) Hydrate policy templates with real contentUri/contentHash

Run the hydration script and provide:
- `-PackageRootPath` pointing to the repo `packages` folder
- `-ContentUriBase` pointing to your blob container URL prefix (or provide a mapping file)
- `-RequiredUamiResourceId` for the UAMI that must be attached to VMs

Example:

```powershell
cd .\scripts
.\hydrate-policy-templates.ps1 `
  -PackageRootPath ..\packages `
  -ContentUriBase "https://<storage>.blob.core.windows.net/<container>" `
  -RequiredUamiResourceId "/subscriptions/<sub>/resourceGroups/<rg>/providers/Microsoft.ManagedIdentity/userAssignedIdentities/<uami>"
```

This produces **portal-importable policy JSON files** under each package:
- `packages/<package>/policy/deployIfNotExists.enhanced.json`

### 4) Import/assign policies in Azure (handled by Terraform)

Terraform should:
- Register required resource providers (including `Microsoft.GuestConfiguration`)
- Deploy prerequisite policies (VM identity + Machine Configuration extension + required UAMI)
- Deploy the per-package `DeployIfNotExists` policies and assign them to the VM scope
- Trigger remediation tasks as needed

### 5) Validate on the VM

For each package, use the package `README.md`:
- It contains the exact local validation commands (registry, auditpol, net accounts, etc.)
- It also describes how Machine Configuration evaluates and remediates the setting

## Troubleshooting

- Ensure the VM has:
  - System-assigned identity enabled (prerequisite)
  - The Machine Configuration extension installed
  - The required package-access UAMI attached
- Ensure policy assignment identities have sufficient RBAC to remediate.



## Output locations

All build and hydration outputs are written outside the package folders.
Configure output folders in `packages/machine-configuration.config.json` under `OutputPaths`.

Default output layout:
- `./output/mof/`
- `./output/zip/`
- `./output/policy/`
