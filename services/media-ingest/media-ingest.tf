
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
}

resource "nomad_acl_policy" "media-ingest" {
  name = "media-ingest-triggers-media-rename"
  job_acl {
    namespace = "media"
    job_id = "media-ingest"
    group = "media-ingest"
    task = "rclone"
  }
  rules_hcl = <<HCL
namespace "media" {
  policy = "read"
  capabilities = ["dispatch-job"]
}

node {
  policy = "read"
}
HCL
}

module "event-listener" {
  source = "../../terraform/_modules/service/event-listener/nomad"
  src = "http"
  job = "media-ingest"
  name = "media-ingest"
  namespace = "media"
}

output "url" {
  description = "The listener url"
  value = "https://evgw.nidi.to/-/${module.event-listener.key}"
}
