terraform {
  backend "consul" {
    path = "nidito/state/bootstrap"
  }

  required_providers {
    consul = {
      source  = "hashicorp/consul"
      version = "~> 2.17.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "~> 2.1.0"
    }
  }

  required_version = ">= 1.0.0"
}
