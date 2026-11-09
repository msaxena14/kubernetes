# Step 1 of the IAM layer: say which real objects these code addresses stand for.
# The resource code itself does not exist yet; Terraform will draft it with
#   terraform plan -generate-config-out=generated.tf
# Import ID formats come from the "Import" section of each resource's Registry page.

# EKS control-plane role. ID = role name.
import {
  to = aws_iam_role.cluster
  id = "AmazonEKSAutoClusterRole"
}

# Worker node role. ID = role name.
import {
  to = aws_iam_role.node
  id = "AmazonEKSAutoNodeRole"
}

# VPC CNI role used through IRSA. ID = role name.
import {
  to = aws_iam_role.cni
  id = "AmazonEKS_CNI"
}

# IAM OIDC provider of the cluster. ID = the provider ARN, built from variables
# so the real account ID and cluster ID never appear in committed code.
import {
  to = aws_iam_openid_connect_provider.cluster
  id = format("arn:aws:iam::%s:oidc-provider/%s", var.account_id, var.oidc_issuer)
}

# The 10 policy attachments, one import per entry in local.attachments.
# ID format for aws_iam_role_policy_attachment: <role-name>/<policy-arn>
import {
  for_each = local.attachments
  to       = aws_iam_role_policy_attachment.this[each.key]
  id       = "${local.role_names[each.value.role]}/arn:aws:iam::aws:policy/${each.value.policy}"
}
