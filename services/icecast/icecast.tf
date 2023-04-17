terraform {
  backend "consul" {
    path = "nidito/state/service/icecast"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.14.0"
    }

    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.17.0"
    }

    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 1.4.19"
    }

    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.25.2"
    }
  }

  required_version = ">= 1.0.0"
}

provider "digitalocean" {
  token = data.vault_generic_secret.do.data.token
}

data "vault_generic_secret" "do" {
  path = "cfg/infra/tree/provider:digitalocean"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "icecast"
  services = ["nidi.to:cajon"]
  configs = ["service:dns"]
}

module "external-dns" {
  source = "../../terraform/_modules/public-dns"
  name = "radio"
}

# TODO: set job and group when https://github.com/hashicorp/terraform-provider-nomad/pull/314 lands
# created with the following command, then imported
# nomad acl policy apply -namespace default -job radio -group radio -task radio icecast-triggers-radio-processing <(cat <<EOF
# namespace "default" {
#   capabilities = ["dispatch-job"]
# }
# EOF
# )
resource "nomad_acl_policy" "icecast" {
  name = "icecast-triggers-radio-processing"
  # job = "radio"
  # group = "radio"
  # task = "radio"
  rules_hcl = <<HCL
namespace "default" {
  capabilities = ["dispatch-job"]
}
HCL
}
