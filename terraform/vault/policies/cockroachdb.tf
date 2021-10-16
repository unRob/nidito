# resource "vault_policy" "cockroachdb" {
#   name = "cockroachdb"

#   policy = <<HCL
# path "kv/nidito/cockroachdb/*" {
#   capabilities = ["read"]
# }

# path "pki_int/issue/cockroachdb" {
#   capabilities = ["create", "update"]
# }

# path "pki_int/certs" {
#   capabilities = ["list"]
# }

# path "pki_int/revoke" {
#   capabilities = ["create", "update"]
# }

# path "pki_int/tidy" {
#   capabilities = ["create", "update"]
# }

# path "pki/cert/ca" {
#   capabilities = ["read"]
# }


# # Allow checking the capabilities of our own token. This is used to validate the
# # token upon startup.
# path "sys/capabilities-self" {
#   capabilities = ["update"]
# }

# # Allow our own token to be renewed.
# path "auth/token/renew-self" {
#   capabilities = ["update"]
# }
# HCL
# }

# resource "vault_pki_secret_backend_role" "cockroachdb" {
#   depends_on = [vault_mount.intermediate]

#   backend            = vault_mount.intermediate.path
#   name               = "cockroachdb"
#   allowed_domains    = ["nidi.to", "service.consul"]
#   allow_subdomains   = true
#   allow_bare_domains = true
#   allow_any_name     = true

#   key_usage = [
#     "DigitalSignature",
#     "KeyAgreement",
#     "KeyEncipherment",
#   ]
# }

# resource "vault_pki_secret_backend_cert" "root_user_cert" {
#   depends_on = [vault_mount.intermediate]

#   backend     = vault_mount.intermediate.path
#   name        = vault_pki_secret_backend_role.cockroachdb.name
#   common_name = "root"

#   ttl = "24h"
# }

# # for use with cdb init
# output "root_cert" {
#   value = vault_pki_secret_backend_cert.root_user_cert.certificate
# }

# output "root_ca" {
#   value = vault_pki_secret_backend_cert.root_user_cert.ca_chain
# }

# output "root_cert_key" {
#   value = vault_pki_secret_backend_cert.root_user_cert.private_key
# }
