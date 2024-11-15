terraform {
  required_version = ">= 1.0.0"
}


variable "name" {
  description = "the service's name"
  type = string
}

variable "policy" {
  description = "a valid HCL policy to use instead of a generated one"
  type = string
  default = ""
}

variable "prefixes" {
  description = "key prefixes paths the service can read from"
  type = map
  default = {}
}

variable "session_prefixes" {
  description = "session prefix permissions"
  type = map
  default = {}
}

variable "service_prefixes" {
  description = "service prefix permissions"
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

variable "create_vault_role" {
  description = "Creates a vault role to be read by nomad tasks at provisioning"
  type = bool
  default = false
}

locals {
  service_prefixes = {
    ("nidito/service/${var.name}") = "write"
    ("nidito/service/${var.name}/*") = "write"
    ("nidito/service/${var.name}/+/*") = "write"
  }
  policy = var.policy != "" ? var.policy : <<-HCL
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

  %{ if length(var.session_prefixes) > 0 }
  %{ for prefix, policy in var.session_prefixes }session_prefix "${prefix}" {
    policy = "${policy}"
  }
  %{ endfor }
  %{ endif }
  %{ if length(var.service_prefixes) > 0 }
  %{ for prefix, policy in var.service_prefixes }service_prefix "${prefix}" {
    policy = "${policy}"
  }
  %{ endfor }
  %{ endif }
  HCL
}

data "terraform_remote_state" "vault" {
  backend = "consul"
  workspace = terraform.workspace == "default" ? "casa" : terraform.workspace
  config = {
    path = "nidito/state/vault"
  }
}

resource "consul_acl_policy" "service" {
  name = "service-${var.name}"
  rules = local.policy
}

output "name" {
  value = consul_acl_policy.service.name
  description = "The generated policy name"
}

resource "vault_consul_secret_backend_role" "service" {
  count = var.create_vault_role ? 1 : 0
  name    = "service-${var.name}"
  backend = data.terraform_remote_state.vault.outputs.consul_backend_name
  policies = [consul_acl_policy.service.name]
  ttl = 600
  max_ttl = 86400
}

output "vault-role" {
  value = var.create_vault_role ? vault_consul_secret_backend_role.service[0].name : ""
  description = "The generated vault role name"
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
  value = var.create_service_token ? vault_generic_secret.service[0].path : ""
  description = "The vault path to the created consul token"
}

# https://developer.hashicorp.com/consul/docs/security/acl/acl-roles
# resource "consul_acl_role" "service" {
#   name = "nomad-workload-${var.name}"
#   policies    = [consul_acl_policy.service.id]
# }
