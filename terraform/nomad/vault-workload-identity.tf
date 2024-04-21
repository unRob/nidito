//https://developer.hashicorp.com/nomad/tutorials/integrate-vault/vault-acl#configure-vault-to-accept-nomad-workload-identities
resource "vault_jwt_auth_backend" "nomad-workload" {
  path = "nomad-workload"
  jwks_url = "https://nomad.service.${terraform.workspace}.consul:5560/.well-known/jwks.json"
  jwt_supported_algs = ["RS256", "EdDSA"]
  default_role = "nomad-workload"
}

resource "vault_jwt_auth_backend_role" "default-workload" {
  backend = vault_jwt_auth_backend.nomad-workload.path
  role_type = "jwt"
  role_name = "nomad-workload"
  bound_audiences = ["vault.io"]
  user_claim = "/nomad_job_id"
  user_claim_json_pointer = true
  claim_mappings = {
    nomad_namespace = "nomad_namespace"
    nomad_job_id = "nomad_job_id"
    nomad_task = "nomad_task"
  }
  token_type = "service"
  token_policies = [vault_policy.nomad-default-workload.id]
  token_period = 30 * 60
  token_explicit_max_ttl = 0
}


resource "vault_policy" "nomad-default-workload" {
  name = "nomad-default-workload"
  policy = <<-HCL
  path "cfg/svc/tree/nidi.to:{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_job_id}}" {
    capabilities = ["read"]
  }

  path "cfg/svc/trees" {
    capabilities = ["list"]
  }

  path "nidito/service/{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_job_id}}" {
    capabilities = ["create", "update", "delete", "list"]
  }

  path "nidito/service/{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_job_id}}/*" {
    capabilities = ["create", "update", "delete", "list"]
  }

  path "nidito/service/{{identity.entity.aliases.AUTH_METHOD_ACCESSOR.metadata.nomad_job_id}}/+/*" {
    capabilities = ["create", "update", "delete", "list"]
  }
  HCL
}

output "nomad-auth-path" {
  value = vault_jwt_auth_backend.nomad-workload.path
}
