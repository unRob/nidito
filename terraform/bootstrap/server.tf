data external inventory {
  program = ["./config.sh", "../../config.yml", "nodes", <<-JQ
  {
    consul: ([ to_entries[] | select( .value | has("consul") ) | .key ]),
    vault: ([ to_entries[] | select( .value | has("vault") ) | .key ]),
    all: ([
      to_entries[] | select( .value | (has("vault") or has("consul")) ) | .key
    ])
  }
  JQ
  ]
}

locals {
  servers = jsondecode(data.external.inventory.result.data)
}

resource consul_acl_policy consul-server {
  for_each = toset(local.servers.consul)
  name        = "server-consul-${each.value}"
  description = "${each.value} server policy"
  datacenters = ["brooklyn"]
  rules       = <<-RULE
    agent_prefix "" {
      policy = "write"
    }

    event_prefix "" {
      policy = "read"
    }

    node_prefix "" {
      policy = "write"
    }

    service_prefix "" {
      policy = "write"
    }

    key_prefix "dns/static-entries" {
      policy = "read"
    }
  RULE
}

resource consul_acl_policy vault {
  name        = "server-vault-policy"
  description = "vault server policy"
  datacenters = ["brooklyn"]
  rules       = <<-RULE
    key_prefix "vault/" {
      policy = "write"
    }

    node_prefix "" {
      policy = "write"
    }

    service "vault" {
      policy = "write"
    }

    agent_prefix "" {
      policy = "write"
    }

    session_prefix "" {
      policy = "write"
    }
  RULE
}


resource consul_acl_token server {
  for_each = toset(local.servers.all)
  description = "server policy for ${each.value}"
  policies = concat(
    (
      contains(local.servers.consul, each.value) ? [consul_acl_policy.consul-server[each.value].name] : []
    ),
    (
      contains(local.servers.vault, each.value) ? [consul_acl_policy.vault.name] : []
    ),
  )
  local = true
}

data consul_acl_token_secret_id server {
  for_each = toset(local.servers.all)
  accessor_id = consul_acl_token.server[each.value].id
}

