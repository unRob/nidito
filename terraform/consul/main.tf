terraform {
  backend "consul" {
    path    = "nidito/state/consul"
  }

  required_version = ">= 0.12.20"
}

resource "consul_prepared_query" "dns-services" {

  template {
    type   = "name_prefix_match"
    regexp = "^(.+)$"
  }

  service = "$${match(1)}"

  name         = "dns-services"
  only_passing = false

  tags    = ["nidito.dns.enabled"]
}