# 04 — Test with Azure Machine Configuration

This guide tests a package end-to-end using Azure Machine Configuration and Azure Policy.

It assumes:
- You can upload package ZIPs to a storage location reachable by the VM.
- A **User Assigned Managed Identity (UAMI)** is used for package access.
- You will import policy JSON via the Azure Portal (or automation outside this repo).
## Azure Portal JSON format: use *.portal.json

Azure Portal has two common ways to create policy definitions:

1. **Create definition (UI fields + JSON editor)**  
   The Portal JSON editor expects the **PolicyDefinitionProperties object** (displayName/mode/metadata/parameters/policyRule), **not** a full wrapper with `{ "properties": { ... } }`.

   Use the `*.portal.json` files created by the scripts in this repo.

2. **Automation / REST**  
   Many automation paths accept the full `{ "properties": { ... } }` wrapper.

This repo therefore writes **two variants** when you build/hydrate policies:

- `deployIfNotExists.enhanced.json` (full wrapper)
- `deployIfNotExists.enhanced.portal.json` (properties-only, for Azure Portal JSON editor)

If you also generate the baseline policy via `New-GuestConfigurationPolicy` during `build.ps1`, a corresponding `*.portal.json` file is written next to the generated JSON.


> Note: The enhanced policy templates in this repo include an additional scope filter that targets **Windows Server** images using the Azure Policy aliases `Microsoft.Compute/imageOffer` and `Microsoft.Compute/imageSKU`.
> This matches typical Azure Marketplace Windows Server images (Offer `WindowsServer*` with SKU `2016*`, `2019*`, `2022*`, `2025*`) and common Windows Server-based offers containing `WS2016`, `WS2019`, `WS2022`, or `WS2025`.
> If you deploy VMs from **custom images** (Shared Image Gallery / imageReference.id) and the offer/SKU fields are not present, the policy may not evaluate those VMs. Adjust the policy condition if needed.


## 1. Build the package ZIP

Example:

```powershell
cd .\packages\win-server-ACCT-001
.\build.ps1
```

Ensure ZIP exists under `output\zip\...`.

## 2. Upload the ZIP to your storage

Upload:
`output\zip\win-server-ACCT-001\win-server-ACCT-001.zip`

The final content URL must match:

`<ContentUriBase>/win-server-ACCT-001.zip`

## 3. Configure ContentUriBase + RequiredUamiResourceId

Edit:

`packages\machine-configuration.config.json`

Set:
- `ContentUriBase` to your storage container URL (no trailing slash required)
- `RequiredUamiResourceId` to the UAMI resource ID

`ControlIdPolicyPrefix` (optional) is used only for policy display names.

## 4. Hydrate the enhanced policy JSON for the package

From the package folder:

```powershell
cd .\packages\win-server-ACCT-001
.\hydrate-policy.ps1
```

This writes:
`output\policy\win-server-ACCT-001\deployIfNotExists.enhanced.json`

It fills:
- `__CONTENT_URI__`
- `__CONTENT_HASH__`
- `__UAMI_RESOURCE_ID__`

It also sets the policy **displayName** to:
`<ControlIdPolicyPrefix><BaseControlId> (Machine Configuration)`
Example:
`tkmx-cm-windows-server-hardening-ACCT-001 (Machine Configuration)`

## 5. Import the policy JSON

In Azure Portal:
- Policy → Definitions → Import definition
- Upload: `deployIfNotExists.enhanced.json`

## 6. Assign prerequisites + identity

You must ensure the VM meets prerequisites:
- Machine Configuration extension installed
- Required UAMI attached to the VM (for package download)
- Policy assignment has remediation identity configured where required

This repo includes shared policies under `policies\` to help model these steps.

## 7. Trigger evaluation and remediation

After policy assignment:
- Wait for policy evaluation cycle or trigger it via portal.
- If DeployIfNotExists is used, start remediation.

## 8. Verify compliance

- Azure Policy compliance view
- Guest Configuration assignment compliance under the VM resource