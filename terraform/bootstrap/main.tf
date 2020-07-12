terraform {
  backend "consul" {
    path    = "nidito/state/bootstrap"
  }

  required_version = ">= 0.12.20"
}
