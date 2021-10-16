
resource "vault_policy" "prometheus" {
  name = "prometheus"

  policy = <<HCL
path "nidito/config/services/ca" {
  capabilities = ["read"]
}

path "nidito/config/services/consul/ports" {
  capabilities = ["read"]
}

path "nidito/service/prometheus/consul" {
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
