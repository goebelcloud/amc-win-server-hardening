# Set up the authoring workstation

## Goal
Packages are built and validated on a Windows authoring VM. The repository structure itself is platform-neutral, but the actual package build is not.

## Prerequisites
- PowerShell 7
- Internet access to PSGallery or an internal mirror repository
- Permission to install PowerShell modules
- Write access to this repository
- Access to the target storage account for package ZIP files

## Install modules
```powershell
pwsh ./authoring-workstation/install-required-modules.ps1
```

The script installs or validates these modules in particular:

- `GuestConfiguration`
- `PSDesiredStateConfiguration`
- `PSDscResources`
- `SecurityPolicyDsc`

It also validates the import and availability of these DSC resources:

- `File`, `Registry`, and `Script`
- `AccountPolicy`, `AuditPolicySubcategory`, and `SecurityOption`

## Repository configuration
`packages/machine-configuration.config.json` is the central configuration file.

Important fields:

- `ContentUriBase`  
  Base URI for uploaded package ZIP files.
- `RequiredUamiResourceId`  
  Default UAMI for the enhanced policy.
- `PolicyDisplayPrefix`  
  Optional prefix for the Azure Policy `displayName`.
- `OutputPaths.PackageZipOutputRoot`
- `OutputPaths.MofOutputRoot`
- `OutputPaths.PolicyOutputRoot`

## Important architecture rules
- Package folders use only `win-server-<Control-ID>`.
- Package folders do not store generated outputs.
- Policy files are generated only from the central templates plus `policy-metadata.json`.
- No `*.portal.json` files exist.
