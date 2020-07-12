data external node-config {
  program = ["pipenv", "run", "python", "${path.module}/dump-node-config.py"]
}

locals {
  j = jsondecode(data.external.node-config.result.data)
}

resource consul_acl_policy consul-server {
  for_each = j.servers.consul
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
  for_each = j.servers.all
  description = "server policy for ${each.name}"
  policies = concat(
    (
      contains(j.servers.consul, each.name) ? [consul_acl_policy.consul-server[each.name].name] : []
    ),
    (
      contains(j.servers.vault, each.name) ? [consul_acl_policy.vault.name] : []
    ),
  )
  local = false
}

data consul_acl_token_secret_id vault {
  accessor_id = "${consul_acl_token.vault.id}"
}
