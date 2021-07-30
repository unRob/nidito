
resource vault_policy http-proxy {
  name = "http-proxy"

  policy = <<HCL
path "kv/nidito/letsencrypt/*" {
  capabilities = ["read"]
}

path "kv/nidito/config/http/zones/*" {
  capabilities = ["read"]
}

path "kv/nidito/config/networks" {
  capabilities = ["read"]
}

path "kv/nidito/config/networks/json" {
  capabilities = ["read"]
}

path "kv/nidito/config/dns" {
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
