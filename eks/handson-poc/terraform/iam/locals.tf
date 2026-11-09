locals {
  # One place for each role's real name; used by both the roles and the imports.
  role_names = {
    cluster = "AmazonEKSAutoClusterRole"
    node    = "AmazonEKSAutoNodeRole"
    cni     = "AmazonEKS_CNI"
  }

  # AWS managed policies attached to each role (read from the real roles).
  policy_attachments = {
    cluster = [
      "AmazonEKSClusterPolicy",
      "AmazonEKSBlockStoragePolicyV2",
      "AmazonEKSComputePolicy",
      "AmazonEKSLoadBalancingPolicy",
      "AmazonEKSNetworkingPolicy",
    ]
    node = [
      "AmazonEKSWorkerNodePolicy",
      "AmazonEKSWorkerNodeMinimalPolicy",
      "AmazonEC2ContainerRegistryPullOnly",
      "AmazonElasticContainerRegistryPublicReadOnly",
    ]
    cni = [
      "AmazonEKS_CNI_Policy",
    ]
  }

  # Flatten into one entry per attachment, keyed "<role>/<policy>":
  #   "cluster/AmazonEKSClusterPolicy" => { role = "cluster", policy = "AmazonEKSClusterPolicy" }
  attachments = merge([
    for role, policies in local.policy_attachments : {
      for policy in policies : "${role}/${policy}" => { role = role, policy = policy }
    }
  ]...)
}
