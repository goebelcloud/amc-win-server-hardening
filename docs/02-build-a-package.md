# Build packages

## Build a single package
Example:

```powershell
pwsh ./packages/win-server-ACCT-001/build.ps1
```

The build script:

1. reads `packages/machine-configuration.config.json`
2. detects the DSC configuration name from `Configuration.ps1`
3. creates the MOF file in the central output path
4. creates the Guest Configuration ZIP in the central output path
5. writes `contentUri`, `contentHash`, and the ZIP path back into `policy-metadata.json`
6. updates the runtime-generated `packages/package-catalog.json` based on the package folders currently present

## Build all packages
```powershell
pwsh ./scripts/build-all.ps1
```

Optional prefix filter:

```powershell
pwsh ./scripts/build-all.ps1 -PackageFolderPrefix "win-server-SECO-"
```

## Output behavior
By default, outputs are created only in the central locations:

- `output/mof/<Control-ID>/`
- `output/zip/<Control-ID>/`

There are intentionally no build artifacts under `packages/win-server-.../`.
