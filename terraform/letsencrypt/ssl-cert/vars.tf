variable "acme_account_key_pem" {
  type = string
  description = "The current ACME account private key in PEM format"
}

variable "datacenter" {
  type = string
  description = "The datacenter's name"
}

variable "dns_zone" {
  type = string
  description = "The datacenter's dns zone name"
}

variable "do_token" {
  type = string
  description = "A DigitalOcean Token to perform DNS record operations"
}
