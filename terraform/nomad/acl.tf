resource "nomad_acl_policy" "admin" {
  count = terraform.workspace == "casa" ? 1 : 0
  name        = "admin"
  // unfortunately, there's no way to grant "access control" permissions, you have
  // to use a management token for that
  description = "can do almost everything"

  # https://developer.hashicorp.com/nomad/tutorials/access-control/access-control-policies#namespace-rules
  rules_hcl = <<-EOF
    namespace "*" {
      policy = "write"
      capabilities = ["alloc-node-exec"]
    }

    node {
      policy = "write"
    }

    agent {
      policy = "write"
    }

    operator {
      policy = "write"
    }

    plugin {
      policy = "read"
    }

    host_volume "*" {
      policy = "write"
    }

  EOF
}


resource "nomad_acl_role" "admins" {
  count = terraform.workspace == "casa" ? 1 : 0
  name        = "admin"
  description = "cluster admin"

  policy {
    name = nomad_acl_policy.admin[0].name
  }
}
