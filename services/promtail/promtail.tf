terraform {
  backend "consul" {
    path = "nidito/state/service/promtail"
  }

  required_version = ">= 1.0.0"
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "promtail"
  paths = [
    "config/services/ca",
    "config/services/consul/ports",
  ]
}

module "consul-policy" {
  source = "../../terraform/_modules/service/consul-policy"
  name = "promtail"
  read_consul_data = true
  create_service_token = true
  create_local_token = true
}
