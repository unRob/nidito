#!/usr/bin/env bash
@milpa.load_util user-input

svc="$MILPA_ARG_NAME"
root="$(milpa nidito service root)"
svc_folder="$root/$svc"

mkdir "$svc_folder" || @milpa.fail "Could not create $svc_folder"

config="$svc_folder/$svc.joao.yaml"
touch "$config"

spec="$svc_folder/$svc.spec.yaml"
touch "$spec" || @milpa.fail "Could not create $spec"
# joao will delete this, but treat file as yaml instead of rendering as json
echo "# yaml" >> "$spec"

if description="$(@milpa.ask "Enter a description for $svc")"; then
  joao set "$spec" description <<<"$description"
fi
if version="$(@milpa.ask "Enter a version for $svc")"; then
  joao set "$spec" packages.self.version <<<"$version"
fi
if docs="$(@milpa.ask "Enter a documentation URL for $svc")"; then
  joao set "$spec" docs <<<"$docs"
fi
if src="$(@milpa.ask "Enter a source URL for $svc")"; then
  joao set "$spec" packages.self.source <<<"$src"
  case "${src}" in
    *github.com*) joao set "$spec" packages.self.check <<<"github-releases";;
    *git.rob.mx*) joao set "$spec" packages.self.check <<<"gitea-releases";;
  esac
fi

cat >"$svc_folder/$svc.tf" <<HCL
terraform {
  backend "consul" {
    path = "nidito/state/service/$svc"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.4.0"
    }
  }

  required_version = ">= 1.0.0"
}
HCL

case "$MILPA_OPT_KIND" in
  nomad)
    cat >"$svc_folder/$svc.nomad" <<HCL
variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "$svc" {
  datacenters = ["$MILPA_OPT_DC"]
  namespace = "home"

  group "$svc" {
    restart {
      delay = "15s"
      attempts = 40
      interval = "10m"
      mode = "delay"
    }

    network {
      port "myPort" {
      }
    }

    task "$svc" {
      driver = ""

      vault {
        role          = "$svc"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      resources {
        cpu        = 50
        memory     = 128
        memory_max = 512
      }

      config {
        ports = ["myPort"]
      }

      service {
        name = "myService"
        port = "myPort"

        check {
          type     = "http"
          path     = "/health"
          interval = "60s"
          timeout  = "2s"
        }

        tags = [
          "nidito.dns.enabled",
          "nidito.http.enabled",
          "nidito.metrics.enabled",
        ]

        meta {
          nidito-acl = "allow altepetl"
        }
      }
    }
  }
}
HCL

    cat >>"$svc_folder/$svc.tf" <<HCL

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "$svc"
}
HCL
    ;;

  http)
    domain="$(@milpa.ask "Enter a domain for $svc")";
    dashed_domain="$(jq -r --null-input --arg "domain" "$domain" '$domain | split(".") | reverse | join("-")')"

    joao set "$spec" build <<<"milpa $svc build"
    joao set "$spec" deploy.credentials <<<"vault://nidito/deploy/$domain"
    joao set "$spec" deploy.src <<<"./dist/$svc"

     cat >"$svc_folder/$svc.tf" <<HCL
terraform {
  backend "consul" {
    path = "nidito/state/service/$domain"
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
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.18.0"
    }
    b2 = {
      source  = "Backblaze/b2"
      version = "~> 0.9.0"
    }
  }

  required_version = ">= 1.0.0"
}

data "vault_generic_secret" "backblaze" {
  path = "cfg/infra/tree/provider:backblaze"
}

data "vault_generic_secret" "cf" {
  path = "cfg/infra/tree/provider:cloudflare"
}

provider "b2" {
  application_key_id = data.vault_generic_secret.backblaze.data.key
  application_key    = data.vault_generic_secret.backblaze.data.secret
}

provider "cloudflare" {
  api_token = data.vault_generic_secret.cf.data.token
}

resource "b2_bucket" "bucket" {
  bucket_name = "$dashed_domain"
  bucket_type = "allPublic"
  bucket_info = {
    "cache-control" = "max-age=3600"
  }

  cors_rules {
    cors_rule_name  = "${dashed_domain}-default"
    allowed_headers = ["*"]
    allowed_operations = [
      "s3_head",
      "s3_get",
    ]
    allowed_origins = [
      "https://$domain",
    ]
    max_age_seconds = 3600
  }
}


data "terraform_remote_state" "rob_mx" {
  backend   = "consul"
  workspace = "default"
  config = {
    path = "nidito/state/rob.mx"
  }
}

resource "cloudflare_record" "cdn_rob_mx" {
  zone_id = data.terraform_remote_state.rob_mx.outputs.cloudflare_zone_id
  name    = "$svc"
  value   = data.terraform_remote_state.rob_mx.outputs.bernal.ip
  type    = "A"
  ttl     = 1
  proxied = true
}

data "b2_account_info" "info" {}

resource "consul_keys" "cdn-config" {
  datacenter = "qro0"
  key {
    path = "cdn/$domain"
    value = jsonencode({
      cert   = "rob.mx"
      proxy  = "dns"
      host   = replace(data.b2_account_info.info.s3_api_url, "https://", "")
      bucket = b2_bucket.bucket.bucket_name
    })
  }
}

resource "b2_application_key" "creds" {
  key_name     = "$dashed_domain"
  bucket_id    = b2_bucket.bucket.bucket_id
  capabilities = [
    "deleteFiles",
    "listAllBucketNames",
    "listBuckets",
    "listFiles",
    "readBucketEncryption",
    "readBucketReplications",
    "readBuckets",
    "readFiles",
    "shareFiles",
    "writeBucketEncryption",
    "writeBucketReplications",
    "writeFiles",
  ]
}

resource "vault_kv_secret" "deploy-config" {
  path = "nidito/deploy/$domain"
  data_json = jsonencode({
    type = "s3"
    bucket = b2_bucket.bucket.bucket_name
    key = b2_application_key.creds.application_key_id
    secret = b2_application_key.creds.application_key
    endpoint = replace(data.b2_account_info.info.s3_api_url, "https://", "")
  })
}

HCL
    ;;
esac
