resource consul_acl_policy gateway {
  name        = "server-consul-gateway"
  description = "gateway policy"
  datacenters = ["casa"]
  rules       = <<-RULE
    event_prefix "" {
      policy = "read"
    }

    service_prefix "" {
      policy = "read"
    }

    key_prefix "dns/static-entries" {
      policy = "read"
    }

    node_prefix "" {
      policy = "read"
    }
  RULE
}

resource consul_acl_token gateway {
  description = "policy for gateway"
  policies = [consul_acl_policy.gateway.name]
  local = true
}

data consul_acl_token_secret_id gateway {
  accessor_id = consul_acl_token.gateway.id
}

output "gateway-token" {
  value = data.consul_acl_token_secret_id.gateway.secret_id
  sensitive = true
}
