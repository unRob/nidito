
resource "vault_policy" "admin" {
  name   = "admin"
  policy = file("./policies/admin.hcl")
}

resource "vault_auth_backend" "userpass" {
  type        = "userpass"
  path        = "userpass"
  description = "username and password for humans"
}

resource "vault_generic_endpoint" "admin" {
  depends_on           = [vault_auth_backend.userpass]
  path                 = "auth/userpass/users/rob"
  ignore_absent_fields = true

  data_json = jsonencode({
    password = var.admin_password
  })
}

resource "vault_identity_entity" "admin" {
  name     = "rob"
  metadata = {}
}

resource "vault_identity_group" "admin" {
  name              = "admin"
  type              = "internal"
  policies          = [vault_policy.admin.id]
  member_entity_ids = [vault_identity_entity.admin.id]
}


resource "vault_identity_entity_alias" "admin-binding" {
  name           = vault_identity_entity.admin.name
  mount_accessor = vault_auth_backend.userpass.accessor
  canonical_id   = vault_identity_entity.admin.id
}
