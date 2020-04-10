resource consul_acl_policy service-prometheus {
  name        = "service-prometheus"
  description = "prometheus policy"
  datacenters = ["brooklyn"]
  rules       = <<-RULE
    service "prometheus" {
      policy = "write"
    }
    service_prefix "" {
      policy = "read"
    }
    node_prefix "" {
      policy = "read"
    }
    key_prefix "prometheus" {
      policy = "write"
    }
    key_prefix "nidito/service/prometheus/" {
      policy = "read"
    }
    key "prometheus" {
      policy = "write"
    }
    RULE
}

resource consul_acl_token service-prometheus {
  description = "prometheus"
  policies = [ consul_acl_policy.service-prometheus.name ]
  local = false
}

data consul_acl_token_secret_id service-prometheus {
  accessor_id = "${consul_acl_token.service-prometheus.id}"
}


resource consul_key_prefix "service-prometheus-config" {
  datacenter = "brooklyn"

  # Prefix to add to prepend to all of the subkey names below.
  path_prefix = "nidito/service/prometheus/"

  subkeys = {
    "consul/token"  = data.consul_acl_token_secret_id.service-prometheus.secret_id
  }
}