terraform {
  backend "consul" {
    path = "nidito/state/nomad"
  }

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.20.0"
    }
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.4.0"
    }
    nomad = {
      source  = "hashicorp/nomad"
      version = "~> 2.2.0"
    }
  }

  required_version = ">= 1.0.0"
}

provider "vault" {
  address = "https://vault.service.${terraform.workspace}.consul:5570"
}

provider "nomad" {
  address = "https://nomad.service.${terraform.workspace}.consul:5560"
}

locals {
  namespaces = {
    infra = {
      runtime       = "stuff providing supporting features for services"
      observability = "misnomer, or a declaration of intent, at best"
      upkeep        = "keeps things working and disasters preventable"
    }
    nidito = {
      home   = "home management"
      media  = "media management"
      rmr    = "republica multitudinaria de roberto"
      code   = "tools for coding around"
      social = "the stuff of horrors"
    }
  }
}

resource "nomad_namespace" "infra" {
  for_each = local.namespaces.infra
  name = "infra-${each.key}"
  description = each.value
}

resource "nomad_namespace" "nidito" {
  for_each = local.namespaces.nidito
  name = each.key
  description = each.value
}
