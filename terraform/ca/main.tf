terraform {
  # backend "consul" {
  #   path = "nidito/state/ca"
  # }

  required_providers {
    tls = {
      source = "hashicorp/tls"
      version = "3.1.0"
    }
  }

  required_version = ">= 1.0.0"
}

variable hosts {
  type = list(string)
}

variable certs {
  type = list(object({
    key = string
    host = string
    cn = string
    names = list(string)
    ips = list(string)
  }))
}

variable ca {
  type = object({
    key = string
    cert = string
  })
  default = {
    key = ""
    cert = ""
  }
}

variable create_ca {
  type = bool
  default = false
}

locals {
  cert_map = { for cert in var.certs: cert.key => cert }
  ca = {
    key = var.create_ca ? tls_private_key.ca[0].private_key_pem : var.ca.key
    cert = var.create_ca ? tls_self_signed_cert.ca[0].cert_pem : var.ca.cert
  }
}

resource "tls_private_key" "ca" {
  count = var.create_ca ? 1 : 0
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_self_signed_cert" "ca" {
  count = var.create_ca ? 1 : 0
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.ca[0].private_key_pem

  subject {
    common_name  = "Nidito CA"
    organization = "nidito"
  }

  validity_period_hours = 24 * 365 * 5
  is_ca_certificate = true
  set_subject_key_id = true

  allowed_uses = [
    "cert_signing",
    "digital_signature",
    "crl_signing",
  ]
}

resource "tls_private_key" "keys" {
  for_each = toset(var.hosts)
  algorithm   = "ECDSA"
  ecdsa_curve = "P384"
}

resource "tls_cert_request" "csr" {
  for_each = local.cert_map
  key_algorithm   = "ECDSA"
  private_key_pem = tls_private_key.keys[each.value.host].private_key_pem

  subject {
    common_name  = each.value.cn
    organization = "nidito"
  }

  dns_names = each.value.names
  ip_addresses = each.value.ips
}

resource "tls_locally_signed_cert" "certs" {
  for_each = local.cert_map
  cert_request_pem   = tls_cert_request.csr[each.value.key].cert_request_pem

  ca_key_algorithm   = "ECDSA"
  ca_private_key_pem = local.ca.key
  ca_cert_pem        = local.ca.cert

  validity_period_hours = 24 * 365

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
    "client_auth"
  ]

  set_subject_key_id = true
}

output "ca" {
  value = local.ca
  sensitive = true
}

output "keys" {
  value = { for host, key in tls_private_key.keys: host => key.private_key_pem }
  sensitive = true
}

output "certs" {
  value = { for name, cert in tls_locally_signed_cert.certs: name => cert.cert_pem }
  sensitive = true
}
