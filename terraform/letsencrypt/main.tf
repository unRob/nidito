terraform {
  backend "consul" {
    path    = "nidito/state/letsencrypt"
  }

  required_providers {
    acme = {
      source = "vancluever/acme"
      version = "~> 2.5.3"
    }
    vault = {
      source = "hashicorp/vault"
      version = "~> 2.23.0"
    }
  }

  required_version = ">= 1.0.0"
}

provider acme {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

data vault_generic_secret le {
  path = "nidito/config/services/letsencrypt"
}

data vault_generic_secret casa_dns {
  path = "nidito/config/datacenters/casa/dns"
}

data vault_generic_secret dns_provider {
  path = "nidito/config/services/dns/external/provider"
}

resource acme_registration account {
  account_key_pem = trim(data.vault_generic_secret.le.data.private_key, "\n")
  email_address   = data.vault_generic_secret.le.data.email
}

module "casa" {
  source = "./ssl-cert"
  acme_account_key_pem = acme_registration.account.account_key_pem
  datacenter = "casa"
  dns_zone = data.vault_generic_secret.casa_dns.data.zone
  do_token = data.vault_generic_secret.dns_provider.data.token
}

data vault_generic_secret nyc1_dns {
  path = "kv/nidito/config/datacenters/nyc1/dns"
}

module "nyc1" {
  source = "./ssl-cert"
  acme_account_key_pem = acme_registration.account.account_key_pem
  datacenter = "nyc1"
  dns_zone = data.vault_generic_secret.nyc1_dns.data.zone
  do_token = data.vault_generic_secret.dns_provider.data.token
}
