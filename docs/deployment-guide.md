# Deployment guide

## Standard sequence

1. Prepare the Windows authoring VM.
2. Set `packages/machine-configuration.config.json`:
   - `ContentUriBase`
   - `RequiredUamiResourceId`
   - optionally `PolicyDisplayPrefix`
3. Build the required packages.
4. Upload the package ZIP files to the defined storage location.
5. Hydrate the policy files from the central templates.
6. Import exactly one policy variant per package:
   - standard / non-enhanced
   - enhanced
7. Create assignments.
8. Validate on the VM.
9. Enable monitoring and alerting.

## Important rules
- no `*.portal.json`
- no package-local policy artifacts
- no extra scope variants
- no `osProfile` / `osDisk` heuristics
- package folders remain stable as `win-server-<Control-ID>`
