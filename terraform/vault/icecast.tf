
resource vault_policy icecast {
  name = "icecast"

  policy = <<HCL
path "kv/nidito/config/services/icecast/*" {
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
