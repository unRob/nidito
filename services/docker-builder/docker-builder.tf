terraform {
  backend "consul" {
    path = "nidito/state/service/docker-builder"
  }

  required_providers {
    vault = {
      source  = "hashicorp/vault"
      version = "~> 4.2.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "4.0.4"
    }
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "docker-builder"
}

# TODO: enable TLS
# data "vault_generic_secret" "ca" {
#   path = "cfg/infra/tree/service:ca"
# }

# locals {
#   hosts = [
#     "popocatepetl",
#     "tepeyac",
#   ]
#   clients = [
#     "roberto",
#   ]
# }

# resource "vault_mount" "pki_docker" {
#    path        = "pki_docker"
#    type        = "pki"
#    description = "pki infra for docker builders"

#    default_lease_ttl_seconds = 86400 // 1 day
#    max_lease_ttl_seconds     = 157680000 // 5 years
# }

# resource "vault_pki_secret_backend_intermediate_cert_request" "csr-request" {
#    backend     = vault_mount.pki_docker.path
#    type        = "internal"
#    common_name = "docker-builder Intermediate Authority"
# }

# resource "tls_locally_signed_cert" "intermediate" {
#   cert_request_pem = vault_pki_secret_backend_intermediate_cert_request.csr-request.csr

#   ca_private_key_pem = data.vault_generic_secret.ca.key
#   ca_cert_pem        = data.vault_generic_secret.ca.cert

#   early_renewal_hours = 24 * 7
#   validity_period_hours = 24 * 365 * 5
#   is_ca_certificate = true


#   allowed_uses = [
#     "key_encipherment",
#     "digital_signature",
#     "server_auth",
#     "client_auth",
#     "cert_signing",
#     "crl_signing",
#     "digital_signature",
#   ]

#   set_subject_key_id = true
# }

# resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
#    backend     = vault_mount.pki_docker.path
#    certificate = tls_locally_signed_cert.intermediate.certificate
# }

# resource "vault_pki_secret_backend_role" "server" {
#    backend          = vault_mount.pki_docker.path
#   #  issuer_ref       = vault_pki_secret_backend_issuer.intermediate.issuer_ref
#    name             = "server.docker-builder"
#    ttl              = 86400
#    max_ttl          = 2592000
#    allow_ip_sans    = true
#    key_type         = "ed25519"
#    key_bits         = 256
#    allowed_domains  = ["nidi.to", "${terraform.workspace}.tepetl.net"]
#    allow_subdomains = true
#    server_flag      = true
# }


# resource "vault_pki_secret_backend_role" "server" {
#    backend          = vault_mount.pki_docker.path
#   #  issuer_ref       = vault_pki_secret_backend_issuer.intermediate.issuer_ref
#    name             = "client.docker-builder"
#    ttl              = 86400
#    max_ttl          = 2592000
#    allow_ip_sans    = true
#    key_type         = "ed25519"
#    key_bits         = 256
#    client_flag      = true
# }
