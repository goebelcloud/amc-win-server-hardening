# 02 — Build a single package

This guide builds one package (MOF + ZIP) from a package folder.

## 1. Pick a package

Packages are under:

`packages\<ControlId>\`

Example:
`packages\win-server-ACCT-001\`

## 2. Build

```powershell
cd .\packages\win-server-ACCT-001
.\build.ps1
```

### Optional: force rebuild

```powershell
.\build.ps1 -ForceRebuild
```

## 3. Where outputs go

Outputs are written under the repo root according to:

`packages\machine-configuration.config.json` → `OutputPaths`

Default layout:
- `output\mof\<ControlId>\...\localhost.mof`
- `output\zip\<ControlId>\<ControlId>.zip`
- `output\policy\<ControlId>\...` (only if policy generation is enabled and config values are not placeholders)

The build does **not** write any outputs into the package folder.

## 4. Build all packages (batch)

From repo root:

```powershell
.\scripts\build-all.ps1
```

Or rebuild everything:

```powershell
.\scripts\build-all.ps1 -ForceRebuild
```
