
resource "vault_policy" "http-proxy" {
  name = "http-proxy"

  policy = <<HCL
path "nidito/config/datacenters/+/dns" {
  capabilities = ["read"]
}

path "nidito/tls/*" {
  capabilities = ["read"]
}

path "nidito/config/http/zones/*" {
  capabilities = ["read"]
}

path "nidito/config/networks" {
  capabilities = ["read", "list"]
}

path "nidito/config/networks/*" {
  capabilities = ["read"]
}

path "nidito/config/dns" {
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
