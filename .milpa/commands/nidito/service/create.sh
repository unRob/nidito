#!/usr/bin/env bash
@milpa.load_util user-input

svc="$MILPA_ARG_NAME"
svc_folder="$NIDITO_ROOT/services/$svc"

mkdir "$svc_folder" || @milpa.fail "Could not create $svc_folder"

config="$svc_folder/$svc.joao.yaml"
touch "$config" || @milpa.fail "Could not create $config"
if description="$(@milpa.ask "Enter a description for $svc")"; then
  joao set "$config" description <<<"$description"
fi
if version="$(@milpa.ask "Enter a version for $svc")"; then
  joao set "$config" package.self.version <<<"$version"
fi
if docs="$(@milpa.ask "Enter a documentation URL for $svc")"; then
  joao set "$config" docs <<<"$docs"
fi
if src="$(@milpa.ask "Enter a source URL for $svc")"; then
  joao set "$config" package.self.source <<<"$src"
  case "${src}" in
    *github.com*) joao set "$config" package.self.check <<<"github-releases";;
    *git.rob.mx*) joao set "$config" package.self.check <<<"gitea-releases";;
  esac
fi

cat >"$svc_folder/$svc.nomad" <<HCL
job "$svc" {
  datacenters = ["$MILPA_OPT_DC"]

  vault {
    policies = ["$svc"]

    change_mode   = "signal"
    change_signal = "SIGHUP"
  }

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
      resources {
        cpu = 50
        memory = 128
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

cat >"$svc_folder/$svc.tf" <<HCL
terraform {
  backend "consul" {
    path = "nidito/state/service/$svc"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.18.0"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "$svc"
}
HCL

