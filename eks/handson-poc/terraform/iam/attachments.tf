# One aws_iam_role_policy_attachment per entry in local.attachments.
resource "aws_iam_role_policy_attachment" "this" {
  for_each = local.attachments

  # Referencing the role resources (not literal names) tells Terraform the
  # attachment depends on the role.
  role = {
    cluster = aws_iam_role.cluster.name
    node    = aws_iam_role.node.name
    cni     = aws_iam_role.cni.name
  }[each.value.role]

  policy_arn = "arn:aws:iam::aws:policy/${each.value.policy}"
}
