path "+/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "nidito/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "nidito/+/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "kv" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "kv/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "kv/+/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "consul" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "consul/+/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "nomad" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "nomad/+/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

# Read system health check
path "sys/health" {
  capabilities = ["read", "sudo"]
}

# Create and manage ACL policies broadly across Vault
path "sys/leases/lookup" {
  capabilities = ["list", "sudo"]
}

path "sys/leases/+/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "identity/*" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}

path "identity/entity" {
  capabilities = ["create", "read", "update", "delete", "list", "sudo"]
}


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


# Allow looking up the current token to validate the token has the
# proper capabilities. This is provided by the "default" policy.
path "auth/token/lookup-self" {
  capabilities = ["read", "update", "create"]
}

# Allow looking up incoming tokens to validate they have permissions to access
# the tokens they are requesting. This is only required if
# `allow_unauthenticated` is set to false.
path "auth/token/lookup" {
  capabilities = ["create", "update", "read"]
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

path "acl/oidc/complete-auth" {
  capabilities = ["read", "create", "update"]
}
