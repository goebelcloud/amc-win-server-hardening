# Sample package template

## Build
```powershell
pwsh ./packages/win-server-CAT-001/build.ps1
```

## Hydrate
```powershell
pwsh ./packages/win-server-CAT-001/hydrate-policy.ps1
```

## Import policy
Import exactly one generated file from `output/policy/<CONTROL-ID>/`.

## Create assignment
Create a policy assignment for the target subscription or management group.

## Verify on the VM
- Verify that the Guest Configuration assignment resource exists on the VM.
- Check the Guest Configuration / DSC log for successful application or drift.
- Verify the target Windows setting with built-in tools and PowerShell.

> This is only a template. Replace the verification steps with the real validation logic for the new control.
