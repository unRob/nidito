terraform {
  backend "consul" {
    path = "nidito/state/service/prometheus"
  }
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "prometheus"
  paths = [
    "config/services/consul/ports",
    "config/services/ca",
  ]
}

module "consul-policy" {
  source = "../../terraform/_modules/service/consul-policy"
  name = "prometheus"

  prefixes = {
    prometheus = "write"
  }

  read_consul_data = true
  create_service_token = true
  create_local_token = false
}
