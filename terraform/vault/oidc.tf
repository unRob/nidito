# https://developer.hashicorp.com/nomad/tutorials/single-sign-on/sso-oidc-vault#create-a-vault-oidc-client

resource "vault_identity_oidc_assignment" "admin" {
  name       = "admin"
  entity_ids = [vault_identity_entity.admin.id]
  group_ids  = [vault_identity_group.admin.id]
}

resource "vault_identity_oidc_key" "infra" {
  name               = "internal"
  allowed_client_ids = ["*"]
  rotation_period    = 3600
  verification_ttl   = 3600
  algorithm          = "RS256"
}

resource "vault_identity_oidc_client" "nomad" {
  name = "nomad"
  key  = vault_identity_oidc_key.infra.name
  redirect_uris = [
    "https://nomad.service.consul:5560/oidc/callback",
    "https://nomad.service.consul:5560/ui/settings/tokens",
    "https://nomad.nidi.to/oidc/callback",
    "https://nomad.nidi.to/ui/settings/tokens",
  ]
  assignments = [
    vault_identity_oidc_assignment.admin.name
  ]

  id_token_ttl     = 2400
  access_token_ttl = 7200
}

resource "vault_identity_oidc_scope" "user" {
  name        = "user"
  template    = <<-JSON
    {"username": {{identity.entity.name}}}
  JSON
  description = "The user scope provides claims using Vault identity entity metadata"
}

resource "vault_identity_oidc_scope" "groups" {
  name        = "groups"
  template    = <<-JSON
    {"groups": {{identity.entity.groups.names}}}
  JSON
  description = "The groups scope provides the groups claim using Vault group membership"
}

resource "vault_identity_oidc_provider" "internal" {
  name          = "internal"
  https_enabled = true
  issuer_host   = "vault.nidi.to"
  allowed_client_ids = [
    vault_identity_oidc_client.nomad.client_id
  ]
  scopes_supported = [
    vault_identity_oidc_scope.user.name,
    vault_identity_oidc_scope.groups.name
  ]
}


data "vault_identity_oidc_client_creds" "nomad" {
  name = vault_identity_oidc_client.nomad.name
}


data "vault_identity_oidc_openid_config" "internal" {
  name = vault_identity_oidc_provider.internal.name
}


output "nomad-oidc" {
  value = jsonencode({
    OIDCDiscoveryURL = data.vault_identity_oidc_openid_config.internal.issuer,
    OIDCClientID     = data.vault_identity_oidc_client_creds.nomad.client_id,
    OIDCClientSecret = nonsensitive(data.vault_identity_oidc_client_creds.nomad.client_secret),
    BoundAudiences = [
      data.vault_identity_oidc_client_creds.nomad.client_id
    ],
    OIDCScopes          = ["groups"],
    AllowedRedirectURIs = vault_identity_oidc_client.nomad.redirect_uris,
    ListClaimMappings = {
      groups = "roles"
    }
  })
  description = <<-EOF
    OIDC config for nomad. Nomad is HC's ugly duckling so it's terraform provider ain't up to date. Thus, we manually run:

    nomad acl auth-method create \
      -default=false \
      -name=vault \
      -token-locality=global \
      -max-token-ttl="8h" \
      -type=oidc \
      -config @<(terraform output -raw nomad-oidc)

    nomad acl binding-rule create \
      -auth-method=vault \
      -bind-type=role \
      -bind-name="admin" \
      -selector="admin in list.roles"
  EOF
}
