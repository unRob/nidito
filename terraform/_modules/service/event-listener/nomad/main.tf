terraform {
  required_version = ">= 1.0.0"
}

variable "job" {
  description = "the job to dispatch"
  type = string
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
}

resource "vault_generic_secret" "nomad-job-dispatcher" {
  path = "nidito/service/event-gateway/listener/${local.key}"
  data_json = jsonencode({
    "kind": "nomad",
    "job": random_id.listener.keepers.job
  })
}

output "key" {
  description = "The listener ID"
  value = local.key
}
