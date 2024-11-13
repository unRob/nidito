terraform {
  backend "consul" {
    path = "nidito/state/service/postgres"
  }

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.21.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.4.0"
    }
  }

  required_version = ">= 1.0.0"
}

data "terraform_remote_state" "ca" {
  backend = "consul"
  config = {
    path = "nidito/state/ca"
  }
}

resource "tls_private_key" "key" {
  algorithm   = "ECDSA"
  ecdsa_curve = "P256"
}

data consul_nodes nodes {
  query_options {
    datacenter = "${terraform.workspace}"
  }
}

resource "tls_cert_request" "csr" {
  private_key_pem = tls_private_key.key.private_key_pem

  subject {
    common_name  = "postgres.service.consul"
    organization = "nidito"
  }

  dns_names = [
    "postgres.service.${terraform.workspace}.consul",
    "postgres.query.consul",
    "postgres.query.${terraform.workspace}.consul",
    "primary.postgres.service.consul",
    "replica.postgres.service.consul",
    "primary.postgres.service.${terraform.workspace}.consul",
    "replica.postgres.service.${terraform.workspace}.consul",
  ]

  ip_addresses = sort([for n in data.consul_nodes.nodes.nodes: n.address])
}

resource "tls_locally_signed_cert" "cert" {
  cert_request_pem = tls_cert_request.csr.cert_request_pem

  ca_private_key_pem = data.terraform_remote_state.ca.outputs.ca.key
  ca_cert_pem        = data.terraform_remote_state.ca.outputs.ca.cert

  early_renewal_hours = 24 * 30
  validity_period_hours = 24 * 365 * 5

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth"
  ]

  set_subject_key_id = true
}

output "key" {
  value     = tls_private_key.key.private_key_pem
  sensitive = true
}

output "cert" {
  value     = tls_locally_signed_cert.cert.cert_pem
  sensitive = true
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "postgres"

  configs = [
    "service:ca"
  ]

  consul_creds = [module.consul-policy.name]
}

module "consul-policy" {
  # https://patroni.readthedocs.io/en/latest/yaml_configuration.html#consul
  source = "../../terraform/_modules/service/consul-policy"
  name = "postgres"

  service_prefixes = {
    postgres = "write"
  }

  session_prefixes = {
    "" = "write"
  }

  create_vault_role = true
}
