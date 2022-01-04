terraform {
  backend "consul" {
    path = "nidito/state/service/radio-processing"
  }
}

module "vault-policy" {
  source = "../../terraform/_modules/service/vault-policy"
  name = "radio-processing"
  paths = [
    "config/services/cdn",
  ]
}
