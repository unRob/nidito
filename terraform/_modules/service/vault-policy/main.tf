terraform {
  required_version = ">= 1.0.0"
}


variable "name" {
  description = "the service's name"
  type = string
}

variable "paths" {
  description = "DEPRECATED vault paths the service can read from"
  type = list(string)
  default = []
}

variable "services" {
  description = "nidito service configs the service can read from"
  type = list(string)
  default = []
}

variable "configs" {
  description = "nidito admin configs the service can read from"
  type = list(string)
  default = []
}


variable "nomad_roles" {
  description = "list of nomad roles to allow this policy to get tokens for"
  type = list(string)
  default = []
}

variable "consul_creds" {
  description = "list of consul credentials to allow this policy to get tokens for"
  type = list(string)
  default = []
}

variable "domain" {
  default = "nidi.to"
}

variable extra_rules {
  default = ""
  description = "Extra HCL rules to apply"
}

locals {
  token_policies = {
    ("sys/capabilities-self") = ["update"]
    ("auth/token/renew-self") = ["update"]
  }
  policies = merge(
    local.token_policies,
    {
      // config
      ("cfg/svc/tree/${var.domain}:${var.name}") = ["read"]
      ("cfg/svc/trees") = ["list"]
      ("cfg/infra/trees") = ["list"]
      // service storage
      ("nidito/service/${var.name}") = ["read", "list"]
      ("nidito/service/${var.name}/*") = ["read", "list"]
      ("nidito/service/${var.name}/+/*") = ["read", "list"]
    },
    { for cfg in var.configs: ("cfg/infra/tree/${cfg}") => ["read"] },
    { for svc in var.services: ("cfg/svc/tree/${svc}") => ["read"] },
    // deprecated
    { for path in var.paths: ("nidito/${path}") => ["read", "list"] },
    // consul credentials
    { for role in var.consul_creds: ("consul-acl/creds/${role}") => ["create", "update", "delete", "read", "list"] },
    (length(var.consul_creds) > 0 ? {
      ("auth/token/create") = ["create", "read", "update", "list"]
    }: {})
  )
}

resource "vault_policy" "service" {
  name = var.name
  policy = <<-HCL
  %{ for path in sort(keys(local.policies)) }path "${path}" {
    capabilities = ${jsonencode(local.policies[path])}
  }

  %{ endfor }
  ${var.extra_rules}
  HCL
}

output "policy" {
  value = vault_policy.service.name
}

data "terraform_remote_state" "vault" {
  backend = "consul"
  workspace = "${terraform.workspace == "default" ? "casa" : terraform.workspace}"
  config = {
    path = "nidito/state/nomad"
  }
}

resource "vault_jwt_auth_backend_role" "service" {
  backend = data.terraform_remote_state.vault.outputs.nomad-auth-path
  role_type = "jwt"
  role_name = var.name
  bound_audiences = ["vault.io"]
  user_claim = "/nomad_job_id"
  user_claim_json_pointer = true
  claim_mappings = {
    nomad_namespace = "nomad_namespace"
    nomad_job_id = "nomad_job_id"
    nomad_task = "nomad_task"
  }
  token_type = "service"
  token_policies = [vault_policy.service.name]
  token_period = 60 * 60 * 6
  token_explicit_max_ttl = 0
}
