terraform {
  backend "consul" {
    path    = "nidito/state/consul"
  }

  required_version = ">= 0.12.0"
}

terraform {
  required_version = ">= 0.12.20"
}
