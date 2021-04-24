resource consul_acl_policy admin {
  name        = "admin-policy"
  description = "admin policy"
  datacenters = ["brooklyn"]
  rules       = <<-RULE
    acl = "write"
    keyring = "write"
    operator = "write"

    agent_prefix "" {
      policy = "write"
    }
    event_prefix "" {
      policy = "write"
    }
    key_prefix "" {
      policy = "write"
    }
    node_prefix "" {
      policy = "write"
    }
    query_prefix "" {
      policy = "write"
    }
    service_prefix "" {
      policy = "write"
    }
    session_prefix "" {
      policy = "write"
    }
  RULE
}

resource consul_acl_token admin {
  description = "admin token"
  policies = [consul_acl_policy.admin.name]
  local = false
}

data consul_acl_token_secret_id admin {
  accessor_id = consul_acl_token.admin.id
}
