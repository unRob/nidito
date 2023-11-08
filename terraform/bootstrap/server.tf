data consul_nodes casa {
  query_options {
    datacenter = "casa"
  }
}

data consul_nodes qro0 {
  query_options {
    datacenter = "qro0"
  }
}

variable "new_node" {
  default = ""
  description = "if set, a new token will be created for the given node name"
}

locals {
  new_node_names = var.new_node == "" ? [] : [var.new_node]
  all_node_names = concat(
    data.consul_nodes.casa.node_names,
    data.consul_nodes.qro0.node_names,
    local.new_node_names
  )
}

# Acl Replication
resource consul_acl_policy acl-replication {
  name = "server-consul-acl-replication"
  description = "https://learn.hashicorp.com/tutorials/consul/access-control-replication-multiple-datacenters?in=consul/security-operations#create-the-replication-token-for-acl-management"
  rules = <<-RULES
  acl = "write"
  operator = "write"
  service_prefix "" {
    policy = "read"
    intentions = "read"
  }
RULES
}

resource consul_acl_token acl-replication {
  description = "ACL replication token"
  policies = [consul_acl_policy.acl-replication.name]
  local = false
}

data consul_acl_token_secret_id acl-replication {
  accessor_id = consul_acl_token.acl-replication.id
}

output "replication-token" {
  value = data.consul_acl_token_secret_id.acl-replication.secret_id
  sensitive = true
}

# Vault
resource consul_acl_policy vault {
  name        = "server-vault-policy"
  description = "vault server policy. https://www.vaultproject.io/docs/configuration/storage/consul#acls"
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

resource consul_acl_token vault {
  description = "vault server token"
  policies = [consul_acl_policy.vault.name]
  local = false
}

data consul_acl_token_secret_id vault {
  accessor_id = consul_acl_token.vault.id
}

output "vault-token" {
  value = data.consul_acl_token_secret_id.vault.secret_id
  sensitive = true
}

# Consul server tokens
resource consul_acl_policy dns {
  name = "server-consul-dns"
  rules = <<-RULES
  node_prefix "" {
    policy = "read"
  }

  service_prefix "" {
    policy = "read"
  }

  query_prefix "" {
    policy = "read"
  }
RULES
}

resource consul_acl_policy consul-server {
  for_each = toset(local.all_node_names)
  name        = "server-consul-${each.value}"
  description = "${each.value} server policy"
  rules       = <<-RULES
    node "${each.value}" {
      policy = "write"
    }

    node_prefix "" {
      policy = "read"
    }

    service_prefix "" {
      policy = "write"
    }
  RULES
}

resource consul_acl_token server {
  for_each = toset(local.all_node_names)
  description = "server policy for ${each.value}"
  policies = [
    consul_acl_policy.consul-server[each.value].name,
    consul_acl_policy.dns.name
  ]
}

data consul_acl_token_secret_id server {
  for_each = toset(local.all_node_names)
  accessor_id = consul_acl_token.server[each.value].id
}

output "server-tokens" {
  value = {for name, token in data.consul_acl_token_secret_id.server : name => token.secret_id }
  sensitive = true
}


# Nomad
resource consul_acl_policy nomad {
  name        = "nomad-server"
  description = "nomad server policy"
  rules       = <<-RULES
    node_prefix "" {
      policy = "read"
    }

    agent_prefix "" {
      policy = "read"
    }

    event_prefix "" {
      policy = "read"
    }

    service_prefix "" {
      policy = "write"
    }

    key_prefix "" {
      policy = "read"
    }

    acl = "write"
  RULES
}

resource consul_acl_token nomad {
  description = "nomad server token"
  policies = [
    consul_acl_policy.nomad.name,
  ]
}

data consul_acl_token_secret_id nomad {
  accessor_id = consul_acl_token.nomad.id
}

output "nomad-token" {
  value = data.consul_acl_token_secret_id.nomad.secret_id
  sensitive = true
}
