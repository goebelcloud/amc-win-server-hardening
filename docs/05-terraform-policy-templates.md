# Terraform / Azure DevOps: central templates + metadata + `jsonencode()`

## Target model
Policy definitions are no longer derived from package-local JSON files or `templatefile` variants.

Instead, use this model:

- central templates under `policy-templates/`
- exactly one `policy-metadata.json` file per package
- definitions and properties built from metadata
- serialization with `jsonencode()` / `ConvertTo-Json`
- no portal-specific files

## Why not `templatefile`
Using `templatefile` with large JSON strings becomes hard to manage once package-specific edge cases accumulate:

- harder to review
- more vulnerable to parameter drift
- harder to understand for package-specific metadata
- unnecessary when the definition can already be built as an object

## Terraform pattern
Example for a single package:

```hcl
locals {
  package_root = "${path.module}/packages/win-server-ACCT-001"
  metadata     = jsondecode(file("${local.package_root}/policy-metadata.json"))

  policy_display_name = var.policy_display_prefix != "" ?
    "${var.policy_display_prefix}${local.metadata.controlId} - ${local.metadata.displayNameSuffix}" :
    "${local.metadata.controlId} - ${local.metadata.displayNameSuffix}"

  policy_definition = {
    name = local.metadata.definitionName
    properties = {
      displayName = local.policy_display_name
      policyType  = "Custom"
      mode        = "Indexed"
      description = local.metadata.descriptionText
      metadata = {
        category      = "Machine Configuration"
        version       = "1.0.0"
        controlId     = local.metadata.controlId
        baseControlId = local.metadata.baseControlId
      }
      parameters = {
        effect = {
          type         = "String"
          defaultValue = "DeployIfNotExists"
        }
        assignmentType = {
          type         = "String"
          defaultValue = local.metadata.assignmentTypeDefault
        }
      }
      policyRule = local.rendered_policy_rule
    }
  }
}

resource "azurerm_policy_definition" "this" {
  name         = local.policy_definition.name
  policy_type  = local.policy_definition.properties.policyType
  mode         = local.policy_definition.properties.mode
  display_name = local.policy_definition.properties.displayName
  description  = local.policy_definition.properties.description
  metadata     = jsonencode(local.policy_definition.properties.metadata)
  parameters   = jsonencode(local.policy_definition.properties.parameters)
  policy_rule  = jsonencode(local.policy_definition.properties.policyRule)
}
```

The important part is the pattern itself:
- read metadata
- assemble the policy object
- serialize to JSON only at the end with `jsonencode()`

## Azure DevOps / PowerShell pattern
Pipelines should also work object-first:

```powershell
$metadata = Get-Content ./packages/win-server-ACCT-001/policy-metadata.json -Raw | ConvertFrom-Json

$policyDefinition = @{
  name = $metadata.definitionName
  properties = @{
    displayName = "{0} - {1}" -f $metadata.controlId, $metadata.displayNameSuffix
    policyType  = "Custom"
    mode        = "Indexed"
    description = $metadata.descriptionText
    metadata    = @{
      category      = "Machine Configuration"
      version       = "1.0.0"
      controlId     = $metadata.controlId
      baseControlId = $metadata.baseControlId
    }
  }
}

$policyJson = $policyDefinition | ConvertTo-Json -Depth 100
```

## Package-specific special values
Package-specific values such as guest-account renames are not modeled as Azure Policy parameters. They remain in `policy-metadata.json` and are injected into the Guest Configuration definition during hydration.

## Conclusion
Prefer a metadata-driven object model and serialize only at the outer edge. That keeps the central templates stable and makes per-package behavior easier to track.
