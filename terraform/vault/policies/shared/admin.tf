
resource "vault_policy" "admin" {
  name = "admin"

  policy = <<HCL
path "nidito" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "nidito/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "kv" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "kv/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}


# Read system health check
path "sys/health" {
  capabilities = ["read", "sudo"]
}

# Create and manage ACL policies broadly across Vault


path "sys/policy" {
  capabilities = ["read", "list", "sudo"]
}

# List existing policies
path "sys/policies/acl" {
  capabilities = ["list"]
}

# Create and manage ACL policies
path "sys/policies/acl/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Enable and manage authentication methods broadly across Vault

# Manage auth methods broadly across Vault
path "auth/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Create, update, and delete auth methods
path "sys/auth/*" {
  capabilities = ["create", "update", "delete", "sudo"]
}

# List auth methods
path "sys/auth" {
  capabilities = ["read"]
}

# Manage secrets engines
path "sys/mounts/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# List existing secrets engines.
path "sys/mounts" {
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
