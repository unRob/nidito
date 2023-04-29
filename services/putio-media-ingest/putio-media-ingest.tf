
terraform {
  backend "consul" {
    path = "nidito/state/service/putio-media-ingest"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.14.0"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "putio-media-ingest"
  configs = ["provider:putio"]
  nomad_roles = [nomad_acl_role.putio.name]
}

/*
TODO: set job and group when https://github.com/hashicorp/terraform-provider-nomad/pull/314 lands
created with the following command, then imported
nomad acl policy apply -namespace default -job putio-media-ingest -group putio-media-ingest -task rclone putio-media-ingest-triggers-tv-renamer <(cat <<EOF
namespace "default" {
  policy = "read"
  capabilities = ["dispatch-job"]
}
EOF
)
*/
resource "nomad_acl_policy" "putio" {
  name = "putio-media-ingest-triggers-tv-renamer"
  # job = "putio-media-ingest"
  # group = "putio-media-ingest"
  # task = "rclone"
  rules_hcl = <<HCL
namespace "default" {
  policy = "read"
  capabilities = ["dispatch-job"]
}
HCL
}

resource "vault_nomad_secret_role" "putio" {
  backend   = "nomad"
  role      = nomad_acl_role.putio.name
  type      = "client"
  policies  = [nomad_acl_policy.putio.name]
}

resource "nomad_acl_role" "putio" {
  name        = "service-putio"
  description = "putio service"

  policy {
    name = nomad_acl_policy.putio.name
  }
}
