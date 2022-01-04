terraform {
  required_version = ">= 1.0.0"
}


variable "name" {
  description = "the service's name"
  type = string
}

variable "prefixes" {
  description = "key prefixes paths the service can read from"
  type = map
  default = {}
}

variable "read_consul_data" {
  description = "allow reading consul service, node and agent metadata"
  type = bool
  default = false
}

variable "create_service_token" {
  description = "Create a service token and store it with vault"
  type = bool
  default = false
}

variable "create_local_token" {
  description = "Create the service token with a local scope"
  type = bool
  default = true
}


locals {
  service_prefixes = {
    ("nidito/service/${var.name}") = "write"
    ("nidito/service/${var.name}/*") = "write"
    ("nidito/service/${var.name}/+/*") = "write"
  }
}

resource "consul_acl_policy" "service" {
  name = "service-${var.name}"
  rules = <<-HCL
  service "${var.name}" {
    policy = "write"
  }

  %{ if var.read_consul_data }service_prefix "" {
    policy = "read"
  }

  agent_prefix "" {
    policy = "read"
  }

  node_prefix "" {
    policy = "read"
  }
  %{ endif }

  %{ for prefix, policy in merge(var.prefixes, local.service_prefixes) }key_prefix "${prefix}" {
    policy = "${policy}"
  }
  %{ endfor }

  key "${var.name}" {
    policy = "write"
  }

  HCL
}

output "name" {
  value = consul_acl_policy.service.name
  description = "The generated policy name"
}

resource "consul_acl_token" "service" {
  count = var.create_service_token ? 1 : 0
  description = "${var.name} service token"
  policies    = [consul_acl_policy.service.name]
  local       = var.create_local_token
}

data "consul_acl_token_secret_id" "service" {
  count = var.create_service_token ? 1 : 0
  accessor_id = consul_acl_token.service[0].id
}

resource "vault_generic_secret" "service" {
  count = var.create_service_token ? 1 : 0
  path = "nidito/service/${var.name}/consul"
  data_json = jsonencode({
    token = data.consul_acl_token_secret_id.service[0].secret_id,
  })
}

output "token_path" {
  value = vault_generic_secret.service[0].path
  description = "The vault path to the created consul token"
}
