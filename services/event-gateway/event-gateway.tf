terraform {
  backend "consul" {
    path = "nidito/state/service/event-gateway"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.15.2"
    }

    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.27.1"
    }
  }

  required_version = ">= 1.2.0"
}

data "vault_generic_secret" "do" {
  path = "cfg/infra/tree/provider:digitalocean"
}

provider "digitalocean" {
  token = data.vault_generic_secret.do.data.token
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "event-gateway"
  nomad_roles = [nomad_acl_role.event-gateway.name]
}

module "external-dns" {
  source = "../../terraform/_modules/public-dns"
  name = "evgw"
}

# TODO: set job and group when https://github.com/hashicorp/terraform-provider-nomad/pull/314 lands
# created with the following command, then imported
# nomad acl policy apply -namespace default -job event-gateway -group event-gateway -task event-gateway event-gateway-triggers-jobs <(cat <<EOF
# namespace "default" {
#   capabilities = ["dispatch-job"]
# }
# EOF
# )
resource "nomad_acl_policy" "event-gateway" {
  name = "event-gateway-triggers-jobs"
  # job = "event-gateway"
  # group = "event-gateway"
  # task = "event-gateway"
  rules_hcl = <<HCL
namespace "default" {
  policy = "read"
  capabilities = ["dispatch-job"]
}
HCL
}

resource "vault_nomad_secret_role" "event-gateway" {
  backend   = "nomad"
  role      = nomad_acl_role.event-gateway.name
  type      = "client"
  policies  = [nomad_acl_policy.event-gateway.name]
}

resource "nomad_acl_role" "event-gateway" {
  name        = "service-event-gateway"
  description = "event-gateway service"

  policy {
    name = nomad_acl_policy.event-gateway.name
  }
}
