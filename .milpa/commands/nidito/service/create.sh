#!/usr/bin/env bash

svc="$MILPA_ARG_NAME"
svc_folder="$(dirname "$MILPA_COMMAND_REPO")/services/$svc"

mkdir "$svc_folder"
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
      delay = "5s"
      # delay_function = "fibonacci"
      # max_delay = "1h"
      # unlimited = true
      attempts = 20
      interval = "20m"
      mode = "delay"
    }

    task "$svc" {
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
      version = "~> 3.7.0"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "$svc"
  paths = [
    "config/services/minio",
    "config/services/dns",
    "config/third-party/$svc",
  ]
}
HCL

