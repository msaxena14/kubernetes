# Issues and fixes

Each entry: Symptom, Cause, Found by, Fix, Prevent. IDs and names are placeholders.

---

### Terraform: `failed to get shared config profile, <profile>`
**Symptom:** `terraform plan` fails on the AWS provider block, even though the profile appears in `~/.aws/config`.
**Cause:** In the config file, non-default profiles must be written `[profile name]`. A bare `[name]` header is only valid in `~/.aws/credentials`. The AWS CLI is lenient about it; the SDK Terraform uses is not.
**Found by:** Reading `~/.aws/config` headers and comparing with the format the SDK expects.
**Fix:** Rename `[name]` to `[profile name]` for every profile.
**Prevent:** Use `aws configure` or `aws configure sso` to create profiles; check headers when hand-editing.

---

### Node group: `You are not authorized to launch instances with this launch template`
**Symptom:** Node group creation fails with an encoded authorization message.
**Cause:** An organization policy explicitly denies `ec2:RunInstances` when the request has no required tag (here: `Team`). The launch template had a `Team` tag only on the template resource itself, not in `TagSpecifications`, so launched instances carried no tag. An explicit deny overrides an admin allow.
**Found by:** `aws sts decode-authorization-message`, which showed the denying statement and its `aws:RequestTag/...` condition, and `describe-launch-template-versions` showing `TagSpecifications: null`.
**Fix:** Add `tag_specifications` for `instance` and `volume` in the launch template, create a new version, and point the node group at it.
**Prevent:** Tag at launch via `tag_specifications`; "template tags" and "resource tags" are different fields in the console. Check the org's required tags before creating launch templates.

---

### Node never joins: nodeadm `yaml: line 5: could not find expected ':'`
**Symptom:** Node group stays `CREATING`; instance is healthy but the kubelet never starts.
**Cause:** User data was pasted with a 2-space indent on every line, so MIME headers and boundaries were not at column 0 and the NodeConfig part was not found. The `--node-labels` value was also wrapped across two lines, which YAML turns into a space. Earlier drafts also had the base64 CA on its own line at column 0 and a missing closing quote.
**Found by:** EC2 console output (`aws ec2 get-console-output`): `nodeadm-config.service` FAILED, and decoding the launch template user data with `base64 -d`.
**Fix:** Rewrite user data with every line starting at column 0, the CA on one line, and labels on one line. Create a new template version.
**Prevent:** Decode the stored user data after creating a version and check the first line is exactly `MIME-Version: 1.0`. Paste into a plain-text editor before the console.

---

### NodeConfig `cidr` is the service CIDR, not the VPC CIDR
**Symptom:** Wrong value placed in `cluster.cidr` in user data.
**Cause:** `cidr` is the Kubernetes Service CIDR (e.g. `172.20.0.0/16`), not the VPC range. `clusterDNS` is the `.10` address inside it.
**Found by:** Comparing with `kubernetesNetworkConfig.serviceIpv4Cidr` from `describe-cluster`.
**Fix:** Use the cluster's service CIDR.
**Prevent:** Read it from `aws eks describe-cluster` rather than guessing.

---

### Private-only endpoint: node joins slowly or never
**Symptom:** nodeadm succeeds, kubelet runs, but the node never registers.
**Cause:** Private-only endpoints resolve through a private hosted zone, which requires both `enableDnsSupport` and `enableDnsHostnames` on the VPC. Hostnames was off by default.
**Found by:** `aws ec2 describe-vpc-attribute --attribute enableDnsHostnames`.
**Fix:** Set `enable_dns_hostnames = true` (and support) on the VPC in Terraform.
**Prevent:** Put both attributes in the VPC module from the start.

---

### `cni plugin not initialized` / vpc-cni `DEGRADED`
**Symptom:** Kubelet reports NetworkPluginNotReady; `aws-node` fails; CoreDNS unschedulable.
**Cause:** The vpc-cni add-on had a Pod Identity association, but the `eks-pod-identity-agent` add-on was not installed, so the pod could not get credentials.
**Found by:** `describe-addon` health issue `K8sResourceNotFound: ... Pod Identity agent is not installed`.
**Fix:** Either install the agent add-on and keep the association, or delete the association and let the CNI use the node role (which needs `AmazonEKS_CNI_Policy`).
**Prevent:** Pick one credential method for the CNI and keep it consistent. Never leave an association without the agent.

---

### `NodeCreationFailure` with a healthy network: wrong access entry type
**Symptom:** Instances launch and boot but "failed to join the kubernetes cluster".
**Cause:** The node role had an access entry of type `EC2` (EKS Auto Mode style, username `{{SessionName}}`) instead of `EC2_LINUX` (`system:node:{{EC2PrivateDNSName}}`). The node name did not match the identity, so registration was rejected. EKS only auto-creates the right entry when none exists.
**Found by:** `aws eks describe-access-entry` for the node role.
**Fix:** Delete the entry and create it with `--type EC2_LINUX` (or recreate the node group with no pre-existing entry).
**Prevent:** Do not pre-create entries for managed node group roles; or create them as `EC2_LINUX`.

---

### nodeadm waits ~6 minutes: `UnauthorizedOperation` on `ec2:DescribeInstances`
**Symptom:** Node boots but the kubelet starts only after minutes.
**Cause:** `AmazonEKSWorkerNodeMinimalPolicy` does not include `ec2:DescribeInstances`, which nodeadm needs at startup. It retried with backoff until another policy happened to grant it.
**Found by:** Console output showing repeated `403 UnauthorizedOperation` before `Instance details populated`.
**Fix:** Use `AmazonEKSWorkerNodePolicy` on the node role.
**Prevent:** Test a minimal policy on a throwaway node first; watch nodeadm's `done! {"duration": ...}`.

---

### Bastion cannot run kubectl
**Symptom:** No access to the private-only API from the bastion.
**Cause:** Three separate layers: the bastion role had no useful permissions (it had broad managed policies but no instance profile attached to the instance); the cluster security group did not allow 443 from the bastion SG; and the role had no EKS access entry.
**Found by:** Instance profile association, security group rules, `list-access-entries`.
**Fix:** Inline policy with `eks:DescribeCluster` and `eks:ListClusters`, attach the instance profile, allow 443 into the cluster SG from the bastion SG, create a `STANDARD` access entry with `AmazonEKSClusterAdminPolicy`.
**Prevent:** IAM permission, network path, and Kubernetes access are three separate checks. Do all three.

---

### Cluster SG and node SG cannot talk
**Symptom:** Nodes cannot reach the API server or the control plane cannot reach kubelets.
**Cause:** The launch template set its own security group, so nodes did not get the cluster SG, and nothing allowed traffic between the two groups.
**Fix:** Cluster SG: allow 443 from the node SG. Node SG: allow 1025-65535 (kubelet 10250, webhooks) from the cluster SG, and all traffic from itself.
**Prevent:** Decide up front which SGs nodes carry; add the rules in Terraform.

---

### Cleanup: cluster delete refused, SG delete `DependencyViolation`
**Symptom:** `delete-cluster` fails; security groups cannot be deleted.
**Cause:** Cluster had deletion protection enabled. The three security groups referenced each other (and one referenced itself).
**Fix:** Disable deletion protection deliberately, delete the cluster, revoke each SG's rules one at a time, then delete the SGs. Then `terraform destroy` for the VPC.
**Prevent:** Order: node group, instances, cluster, SGs, VPC, then launch template, key pair, IAM.

---

### Debugging was slow without logs
**Cause:** Control plane logging was off, so there were no authenticator or API logs to read.
**Prevent:** Enable `api` and `authenticator` logging at cluster creation; use `get-console-output` for node boot logs when there is no SSH or SSM.

---

## Second build

### Stale cluster name in user data after a rebuild
**Symptom:** Caught before it failed: user data was correct in format but `name:` still held the previous cluster's name.
**Cause:** The cluster was recreated with a new name and endpoint/CA were updated, but `name` was missed. nodeadm uses the name for kubelet authentication, so the node would never have joined, with no obvious error.
**Found by:** Decoding the launch template's user data with `base64 -d` and reading it against the new cluster.
**Fix:** New launch template version with the right name; a node group in `CREATING` cannot change its template version, so delete it and recreate.
**Prevent:** Diff endpoint, CA, service CIDR and name against `describe-cluster` every time a cluster is rebuilt.

---

### VPC CNI add-on created with no credentials source
**Symptom:** Caught before it failed: add-on `ACTIVE`, but `serviceAccountRoleArn: None` and no Pod Identity association.
**Cause:** With neither configured, `aws-node` falls back to the node role. The node role had no `AmazonEKS_CNI_Policy`, so the CNI could not call EC2 and nodes would stay `NotReady`.
**Found by:** `aws eks describe-addon --query addon.serviceAccountRoleArn` before creating the node group.
**Fix:** Either set the IRSA role on the add-on, or attach `AmazonEKS_CNI_Policy` to the node role. The second was chosen.
**Prevent:** Decide the CNI's credential source up front and verify it before the node group is created.

---

### Create-cluster wizard offers the cluster role for the CNI's Pod Identity role
**Symptom:** The "Pod Identity IAM role for service account: aws-node" dropdown showed the cluster role selected.
**Cause:** The dropdown lists existing roles and the cluster role was preselected. It trusts `eks.amazonaws.com`, but Pod Identity needs `pods.eks.amazonaws.com`; any selection also creates an association that needs the agent add-on.
**Found by:** Reading the wizard screenshot and the review page ("EKS Pod Identity (0)" is what you want).
**Fix:** Clear it, or remove VPC CNI from the wizard and add it later from the Add-ons tab.
**Prevent:** Check the Pod Identity section on the review page shows no associations.

---

### IAM role wizard freezes the browser tab
**Symptom:** Clicking "create role" in the IAM console hung the Chrome tab.
**Cause:** The machine was out of memory (heavy swap, compressed memory). The permissions step renders the entire managed-policy list. AWS APIs were healthy (CLI calls returned in 1 to 3 seconds).
**Found by:** Checking process memory and swap on the laptop, and timing IAM/STS/EKS API calls from the CLI.
**Fix:** Create the role from the CLI instead.
**Prevent:** Close heavy tabs and restart a machine with days of uptime and swap in use; prefer the CLI for IAM.

---

### IRSA needs an IAM OIDC provider that EKS does not create
**Symptom:** The cluster had an OIDC issuer URL but no matching provider in IAM.
**Cause:** `identity.oidc.issuer` exists from cluster creation, but the IAM OIDC provider must be registered separately before a role can trust it.
**Found by:** Listing `iam list-open-id-connect-providers` and matching the cluster's OIDC id.
**Fix:** `aws iam create-open-id-connect-provider --url <issuer> --client-id-list sts.amazonaws.com`.
**Prevent:** Remember to delete the provider at teardown; it is not removed with the cluster.

---

### zsh swallowed shell variables in JSON and loops
**Symptom:** `MalformedPolicyDocument`, and `InvalidSecurityGroupRuleId.Malformed` when passing several IDs.
**Cause:** In zsh, `$ISS:aud` is parsed as a `:a` modifier on `$ISS`, which mangled the trust policy. An unquoted variable holding several tab-separated IDs is not word-split like in bash.
**Found by:** Validating the generated JSON (`python3 -c 'import json; json.load(...)'`) and echoing the arguments.
**Fix:** Use `${VAR}` in JSON; loop over IDs one at a time.
**Prevent:** Validate generated JSON before calling AWS; brace every variable.

---

### Nodes can simply use the cluster security group
**Symptom:** No need for separate node/cluster SG rules.
**Cause:** A launch template that sets no security groups makes EKS attach the cluster security group to the nodes. The cluster SG allows all traffic from itself and the control plane ENIs carry it, so node-to-API (443), kubelet (10250) and node-to-node traffic all work.
**Found by:** Reading the instance's `NetworkInterfaces[].Groups` after launch.
**Fix:** Leave security groups out of the launch template; add one rule for the bastion (443 from the bastion SG to the cluster SG).
**Prevent:** Only add a separate node SG if there is a reason to isolate nodes.

---

### Node group `CREATING` cannot change its launch template version
**Symptom:** Needed a new template version on a node group that was already creating.
**Cause:** The version is fixed while creating.
**Fix:** Delete the node group and create a new one pinned to the corrected version.
**Prevent:** Verify the template version contents before creating the node group.

---

### `kubectl` on the bastion: `You must be logged in to the server`
**Symptom:** On the bastion, every `kubectl` command fails with `the server has asked for the client to provide credentials`.
**Cause:** The network path and the IAM role were both fine (the API server answered, and `update-kubeconfig` worked), but the bastion's role had no EKS access entry. Kubernetes did not know who the caller was. Only the cluster creator, the node role and the EKS service role had entries.
**Found by:** `aws eks list-access-entries` showed three principals and not the bastion role; the instance's role was read from its instance profile association. An authentication error (rather than a timeout) means the request reached the API server.
**Fix:** `create-access-entry` (type `STANDARD`) plus `associate-access-policy` with `AmazonEKSClusterAdminPolicy` at cluster scope.
**Prevent:** Treat any new `kubectl` user (bastion, CI, teammate) as three tasks: IAM permission, network path, access entry. See build-log step 10.
