terraform {
  backend "consul" {
    path = "nidito/state/service/radio"
  }
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "icecast"
  paths = [
    "config/services/minio",
    "config/services/dns",
  ]
}

module "external-dns" {
  source = "../../terraform/_modules/service/public-dns"
  name = "radio"
}
