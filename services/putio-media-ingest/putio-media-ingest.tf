
terraform {
  backend "consul" {
    path = "nidito/state/service/putio-media-ingest"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 2.23.0"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "putio-media-ingest"
  configs = ["provider:putio"]
}
