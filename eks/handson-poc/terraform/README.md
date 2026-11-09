# Terraform: importing the existing EKS build

The cluster in [../docs](../docs) was built by hand. This folder brings it under Terraform with import blocks, one layer at a time, each layer with its own state so a mistake in one cannot touch another.

| Layer | Folder | What it covers | Status |
|---|---|---|---|
| 1 | [iam](iam) | Cluster, node and CNI roles, their 10 policy attachments, the OIDC provider | imported, plan shows no changes |
| 2 | [eks](eks) | Launch template, 3 add-ons, 3 access entries and 2 policy associations, the node group, the cluster | imported, plan shows no changes |

The VPC layer lives in the separate `terraform` repository.

## Layout of the `eks` layer
One module per component; `main.tf` wires them together.
```
eks/
├── main.tf          calls the five modules
├── data.tf          lookups: cluster, private subnets, VPC default security group
├── moved.tf         old address -> module address, so state is updated, not recreated
├── imports.tf       how each resource was imported (kept to rebuild state from scratch)
├── variables.tf, provider.tf, versions.tf, terraform.tfvars.example
└── modules/
    ├── cluster/          control plane
    ├── launch-template/  node template and user_data.tftpl
    ├── node-group/       managed node group
    ├── addons/           vpc-cni, coredns, kube-proxy
    └── access-entries/   node, bastion and admin entries and their policies
```
The `iam` layer stays flat: it is small and its resources are tightly related.

**Why modules need `moved` blocks:** a resource's address includes the module it lives in. Moving code into a module without telling Terraform looks like "delete the old one, create a new one" (a replaced cluster). `moved` blocks say it is the same object, and the plan shows `has moved to ...` with nothing destroyed.

## Rules for this folder
- State files, `.terraform/`, `terraform.tfvars` and `generated.tf` are git-ignored. State holds real resource details; never commit it.
- Real identifiers (account ID, OIDC issuer, ARNs) go in `terraform.tfvars` only. Code uses variables. Each layer ships a `terraform.tfvars.example` that describes every value in words.
- Never apply a plan that says `must be replaced` or `will be destroyed` for an imported resource. Fix the code until the plan shows no changes.

## The import loop (per layer)
1. Write `import` blocks (`imports.tf`).
2. `terraform plan -generate-config-out=generated.tf` drafts the resource code.
3. Clean the draft into real files (`main.tf`), replacing identifiers with variables, then delete `generated.tf`.
4. `terraform plan` until it reports no changes; then `terraform apply` (it only writes state).

Run each layer from its own folder:
```bash
cd iam && export AWS_PROFILE=<profile> && terraform init
```
