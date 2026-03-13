# Test with Azure Machine Configuration

## Sequence

### 1. Build the package
```powershell
pwsh ./packages/win-server-ACCT-001/build.ps1
```

### 2. Upload the ZIP
The generated file is stored by default under:

```text
output/zip/ACCT-001/win-server-ACCT-001.zip
```

This ZIP must be reachable under the URI formed from `ContentUriBase` plus the file name.

### 3. Hydrate the policy files
```powershell
pwsh ./packages/win-server-ACCT-001/hydrate-policy.ps1
```

Expected outputs:

- `output/policy/ACCT-001/deployIfNotExists.json`
- `output/policy/ACCT-001/deployIfNotExists.enhanced.json`

### 4. Import policy
Import exactly one of the hydrated definitions:

- standard / non-enhanced
- enhanced

No portal-specific variants are intentionally provided.

### 5. Create the assignment
Azure Policy parameters:

- `effect`
- `assignmentType`
- enhanced only: `requiredUserAssignedIdentityResourceId`

Do not pass these as Azure Policy parameters:

- `contentUri`
- `contentHash`
- `contentManagedIdentity`
- package-specific special values such as rename parameters

### 6. Verify on the VM
Verification must always cover three levels:

1. The Guest Configuration assignment really exists on the VM.
2. Guest Configuration / agent logs show a successful evaluation or application.
3. The actual Windows target setting is in the expected state when checked with built-in tools.

The package-specific details are documented directly in the `README.md` file of each package folder.
