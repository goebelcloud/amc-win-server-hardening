# package_template

This directory contains a complete sample package that can be copied as the starting point for a new control.

## Usage

1. Copy `win-server-CAT-001` to `packages/win-server-<CONTROL-ID>`.
2. Update `Configuration.ps1` with the real Windows setting.
3. Update `policy-metadata.json`:
   - `controlId`
   - `baseControlId`
   - `definitionName`
   - `displayNameSuffix`
   - `descriptionText`
   - `assignmentTypeDefault`
   - `guestConfigurationName`
   - optionally `packageParameters`
4. Replace the sample README with a real validation checklist for the new control.
5. Build the package with `pwsh ./packages/win-server-<CONTROL-ID>/build.ps1`.
6. Upload the generated ZIP and then run `hydrate-policy.ps1`.

## Note

The build / hydrate scripts in the template expect the template to be copied into this repository so that `packages/package-metadata.helpers.ps1` and `packages/machine-configuration.config.json` can be found. The central `packages/package-catalog.json` starts empty/minimal and is populated only during build / hydrate based on the package folders that actually exist.
