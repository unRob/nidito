resource "vault_token" "admin" {
  policies = ["admin"]
  renewable = true
  ttl = "8760h"
}

output "admin-token" {
  value = vault_token.admin.client_token
  sensitive = true
}
