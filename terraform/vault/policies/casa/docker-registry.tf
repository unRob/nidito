
resource "vault_policy" "docker-registry" {
  name = "docker-registry"

  policy = <<HCL
path "nidito/config/services/dns" {
  capabilities = ["read"]
}

# Allow checking the capabilities of our own token. This is used to validate the
# token upon startup.
path "sys/capabilities-self" {
  capabilities = ["update"]
}

# Allow our own token to be renewed.
path "auth/token/renew-self" {
  capabilities = ["update"]
}
HCL
}
