# 06 — Quality check summary

This bundle was statically checked before packaging.

## Checks performed

- 50 package folders present under `packages/`
- Excel control list matches package IDs 1:1
- All policy JSON files parse successfully
- All policy files contain the required DINE fields:
  - `then.details.name`
  - `then.details.existenceCondition`
  - `then.details.evaluationDelay`
- No invalid VM extension alias references remain
- No invalid `like` / `notLike` patterns with multiple `*` wildcards remain
- Portal policy variants have no outer `properties` wrapper
- Wrapped/sample policy variants do have the outer `properties` wrapper
- Package-specific policy identifiers match the package folder ID
- Each package contains the expected source files
- No generated outputs (`.zip`, `.mof`, `output/`, `out/`) exist inside package folders

## Limitations of this check

This was a **static** quality check. It does **not** execute PowerShell, DSC compilation, Azure Policy deployment, or Azure Machine Configuration on a live VM.
