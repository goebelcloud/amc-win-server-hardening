# Step-by-step guides (index)

This repository uses **one package per hardening setting** for Azure Machine Configuration (Guest Configuration).

Control IDs used for packages/ZIPs/content URIs are prefixed with `win-server-` (example: `win-server-ACCT-001`).

`packages/machine-configuration.config.json` contains `ControlIdPolicyPrefix`, which is used **only** to prefix Azure Policy **displayName** values (human-readable). It is not used for ZIP names or content URIs.

## Guides

1. [Build/prepare the authoring VM](01-authoring-workstation-setup.md)
2. [Build a single package](02-build-a-package.md)
3. [Test a package locally (no Azure)](03-test-package-locally.md)
4. [Test with Azure Machine Configuration](04-test-with-azure-machine-configuration.md)

Additional docs:
- [Deployment guide](deployment-guide.md)
- [PoV runbook](pov-guide.md)

- [Terraform deployment of hydrated policies](05-terraform-policy-templates.md)
