terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "2.16.0"
    }
  }

  required_version = ">= 1.0.0"
}


data "terraform_remote_state" "external-dns" {
  backend = "consul"
  workspace = "default"
  config = {
    path = "nidito/state/external-dns"
  }
}

variable "name" {
  description = "the service's name"
  type = string
}

variable "ttl" {
  description = "This record's time-to-live in seconds"
  type = number
  default = 3600
}


resource "digitalocean_record" "cname" {
  domain = data.terraform_remote_state.external-dns.outputs.zone
  type   = "CNAME"
  name   = var.name
  ttl    = var.ttl
  value  = "${data.terraform_remote_state.external-dns.outputs.zone}."
}
