# Monitoring and observability

## Goal
The package set should be monitorable both per VM and across subscriptions or management groups.

## 1. Verify Guest assignments
A successful validation path should always answer these questions:

- Does the expected Guest Configuration assignment exist on the VM?
- Does the assignment reference the expected package?
- Is the compliance result as expected?
- Do the local Guest Configuration / DSC logs confirm the same outcome?

What matters is not only that some assignment exists, but that the expected Guest Configuration package is actually referenced.

## 2. Azure Resource Graph
Use a Resource Graph query for a tenant-wide overview:

```kusto
resources
| where type contains "guestconfigurationassignments"
| project subscriptionId, resourceGroup, type, name, id, properties
| order by subscriptionId asc, resourceGroup asc, name asc
```

For an operational dashboard, it is useful to extract additional fields such as:
- VM name
- package / assignment name
- compliance status
- last modification time

## 3. Azure Monitor alerting
Two practical patterns:

### A. Scheduled query alert
Regularly evaluate Resource Graph or Log Analytics for cases where:
- an assignment is missing
- compliance is not reached
- the expected package is not assigned

### B. Policy / compliance-based alert
- For governance views, Azure Policy compliance can also be used.
- For incident handling, it should still be obvious which VM and which package are affected.

## 4. Azure Managed Grafana
For management views, a dashboard on top of Azure Monitor / Log Analytics is recommended with metrics such as:

- assignment count per subscription
- non-compliant VM count per control ID
- trend over time
- distribution by resource group, subscription, or control category

Recommended panels:
- total assignment count
- non-compliant VMs by `controlId`
- top resource groups with open deviations
- per-VM drilldown to the affected package

## 5. Minimum operational view
At minimum, maintain:

1. a list of all expected Guest assignments
2. a list of missing or non-compliant assignments
3. a technical log view for Guest Configuration / agent errors
4. a functional view by control ID
