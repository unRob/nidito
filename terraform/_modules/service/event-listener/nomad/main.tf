terraform {
  required_version = ">= 1.0.0"
  required_providers {
    consul = {
      source = "hashicorp/consul"
      version = "2.20.0"
    }
  }
}

variable "job" {
  description = "the job to dispatch"
  type = string
}

variable "name" {
  description = "the name of this event"
  type = string
}

variable "namespace" {
  description = "the namespace of the job to dispatch"
  type = string
}


variable "src" {
  description = "the source mechanism that will dispatch this nomad job"
  default = "http"
  validation {
    condition = contains(["http", "consul"], var.src)
    error_message = "Unknown source type ${var.src}"
  }
}


resource "random_id" "listener" {
  keepers = {
    # tie job name to the random id
    job = var.job
  }

  byte_length = 32
}

locals {
  key = "${var.job}-${random_id.listener.hex}"
  path = replace(replace(var.name, "/([^a-z0-9])/i", "-"), "/-{2,}/", "-")
  listener = jsonencode({
    source = merge({kind = var.src}, var.src == "http" ? {
      kind = var.src
      path = "${local.path}-${random_id.listener.hex}"
    } : {
      kind = var.src

    })
    sink = {
      kind = "nomad"
      job = random_id.listener.keepers.job
      namespace = var.namespace
    }
  })
}

resource "vault_generic_secret" "nomad-job-dispatcher" {
  path = "nidito/service/event-gateway/listener/${local.key}"
  data_json = local.listener
}

resource "consul_keys" "listener" {
  key {
    path = "nidito/service/event-gateway/listener/${var.name}"
    value = local.listener
  }
}

output "key" {
  description = "The listener ID"
  value = local.key
}
