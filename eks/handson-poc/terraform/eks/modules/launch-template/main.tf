locals {
  # Node bootstrap (nodeadm NodeConfig inside MIME). The template must produce
  # exactly the text stored in the real template, including NO trailing newline.
  user_data = templatefile("${path.module}/user_data.tftpl", {
    cluster_name          = var.cluster_name
    api_endpoint          = var.api_endpoint
    certificate_authority = var.certificate_authority
    service_cidr          = var.service_cidr
    cluster_dns           = cidrhost(var.service_cidr, 10) # the .10 address: CoreDNS
  })
}

resource "aws_launch_template" "nodes" {
  name      = "${var.cluster_name}-lt"
  image_id  = var.ami_id
  key_name  = var.key_name
  user_data = base64encode(local.user_data)

  # The real template defines one network interface with only the device index;
  # subnet and security groups are deliberately left to the node group.
  network_interfaces {
    device_index = 0
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "${var.cluster_name}-lt"
      Team = var.team
    }
  }
}
