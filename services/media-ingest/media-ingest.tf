
terraform {
  backend "consul" {
    path = "nidito/state/service/media-ingest"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.0.0"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "media-ingest"
  configs = ["provider:putio"]
  nomad_roles = [nomad_acl_role.media-ingest.name]
}

resource "nomad_acl_policy" "media-ingest" {
  name = "media-ingest-triggers-media-rename"
  job_acl {
    job_id = "media-ingest"
    group = "media-ingest"
    task = "rclone"
  }
  rules_hcl = <<HCL
namespace "default" {
  policy = "read"
  capabilities = ["dispatch-job"]
}

node {
  policy = "read"
}
HCL
}

resource "vault_nomad_secret_role" "media-ingest" {
  backend   = "nomad"
  role      = nomad_acl_role.media-ingest.name
  type      = "client"
  policies  = [nomad_acl_policy.media-ingest.name]
}

resource "nomad_acl_role" "media-ingest" {
  name        = "service-media-ingest"
  description = "media-ingest service"

  policy {
    name = nomad_acl_policy.media-ingest.name
  }
}

module "event-listener" {
  source = "../../terraform/_modules/service/event-listener/nomad"
  job = "media-ingest"
}

output "url" {
  description = "The listener url"
  value = "https://evgw.nidi.to/-/${module.event-listener.key}"
}
