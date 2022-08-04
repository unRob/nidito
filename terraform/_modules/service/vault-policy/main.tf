terraform {
  required_version = ">= 1.0.0"
}


variable "name" {
  description = "the service's name"
  type = string
}

variable "paths" {
  description = "vault paths the service can read from"
  type = list(string)
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
      ("nidito/service/${var.name}") = ["read", "list"]
      ("nidito/service/${var.name}/*") = ["read", "list"]
      ("nidito/service/${var.name}/+/*") = ["read", "list"]
    },
    { for path in var.paths: ("nidito/${path}") => ["read", "list"] },
    { for role in var.nomad_roles: ("nomad/creds/${role}") => ["write"] },
    { for role in var.consul_creds: ("consul-acl/creds/${role}") => ["create", "update", "delete", "read", "list"] },
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
