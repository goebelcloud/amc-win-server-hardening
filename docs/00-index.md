# Documentation index

- `01-authoring-workstation-setup.md`  
  Prerequisites for the Windows authoring workstation and the required PowerShell modules.

- `02-build-a-package.md`  
  Build one package or all packages with central output paths.

- `03-test-package-locally.md`  
  Validate generated ZIP packages locally with the GuestConfiguration module.

- `04-test-with-azure-machine-configuration.md`  
  End-to-end Azure test flow: build, upload, hydration, policy import, assignment, and verification.

- `05-terraform-policy-templates.md`  
  Recommended IaC approach with central templates, package metadata, and `jsonencode()`.

- `06-quality-check-summary.md`  
  Summary of the static quality checks for this package set.

- `07-monitoring-observability.md`  
  Monitoring of Guest assignments, Azure Monitor alerting, Resource Graph, and Azure Managed Grafana.

- `deployment-guide.md`  
  Compact sequence for the regular rollout path.

- `pov-guide.md`  
  Recommended proof-of-value / pilot sequence with the default baseline, optional packages, and the intentionally removed controls.

- `../package_template/`  
  Template for creating new packages, including a working sample structure.
