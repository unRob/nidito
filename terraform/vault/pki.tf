
# # RootCA
# resource "vault_mount" "root" {
#   path = "pki"
#   type = "pki"

#   max_lease_ttl_seconds = 315360000
# }

# resource "vault_pki_secret_backend_root_cert" "root_ca" {
#   backend = vault_mount.root.path

#   type        = "internal"
#   common_name = "nidi.to"
#   ttl         = "315360000"
# }

# resource "vault_pki_secret_backend_config_urls" "config_urls" {
#   backend                 = vault_mount.root.path
#   issuing_certificates    = ["http://vault.consul.service:5570/v1/pki/ca"]
#   crl_distribution_points = ["http://vault.consul.service:5570/v1/pki/crl"]
# }

# # IntermediateCA
# resource "vault_mount" "intermediate" {
#   depends_on = [vault_mount.root]
#   path       = "pki_int"
#   type       = "pki"

#   max_lease_ttl_seconds = 157680000
# }

# resource "vault_pki_secret_backend_intermediate_cert_request" "intermediate" {
#   depends_on = [vault_mount.intermediate]

#   backend     = vault_mount.intermediate.path
#   type        = "internal"
#   common_name = "nidi.to Intermediate Authority"
# }

# resource "vault_pki_secret_backend_root_sign_intermediate" "cert" {
#   depends_on = [vault_mount.intermediate]

#   backend     = vault_mount.root.path
#   common_name = vault_pki_secret_backend_intermediate_cert_request.intermediate.common_name

#   csr = vault_pki_secret_backend_intermediate_cert_request.intermediate.csr
#   ttl = 157680000
# }

# resource "vault_pki_secret_backend_intermediate_set_signed" "intermediate" {
#   depends_on = [vault_mount.intermediate]

#   backend     = vault_mount.intermediate.path
#   certificate = vault_pki_secret_backend_root_sign_intermediate.cert.certificate
# }

# resource "vault_pki_secret_backend_role" "star_nidito" {
#   depends_on = [vault_mount.intermediate]

#   backend            = vault_mount.intermediate.path
#   name               = "nidi-to"
#   allowed_domains    = ["nidi.to", "service.consul"]
#   allow_subdomains   = true
#   allow_bare_domains = false

#   key_usage = [
#     "DigitalSignature",
#     "KeyAgreement",
#     "KeyEncipherment",
#   ]
# }
