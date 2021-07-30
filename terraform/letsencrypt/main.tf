terraform {
  backend "consul" {
    path    = "nidito/state/letsencrypt"
  }

  required_providers {
    acme = {
      source = "vancluever/acme"
       version = "~> 2.5.2"
    }
    vault = {
      source = "hashicorp/vault"
      version = "~> 2.20.0"
    }
  }

  required_version = ">= 0.13.0"
}

provider acme {
  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

data vault_generic_secret le {
  path = "kv/nidito/config/services/letsencrypt"
}

data vault_generic_secret dns {
  path = "kv/nidito/config/dns"
}

data vault_generic_secret dns_provider {
  path = "kv/nidito/config/dns/external/provider"
}

resource acme_registration account {
  account_key_pem = data.vault_generic_secret.le.data.private_key
  email_address   = data.vault_generic_secret.le.data.email
}

resource acme_certificate cert {
  account_key_pem           = acme_registration.account.account_key_pem
  common_name               = data.vault_generic_secret.dns.data.zone
  subject_alternative_names = ["*.${data.vault_generic_secret.dns.data.zone}"]

  recursive_nameservers = ["1.1.1.1:53", "8.8.8.8:53"]

  dns_challenge {
    provider = "digitalocean"
    config = {
      DO_AUTH_TOKEN = data.vault_generic_secret.dns_provider.data.token
      DO_PROPAGATION_TIMEOUT = 60
      DO_TTL = 30
    }
  }
}

resource vault_generic_secret certificate {
  path = "kv/nidito/letsencrypt/cert/${data.vault_generic_secret.dns.data.zone}"
  data_json = jsonencode({
    private_key = acme_certificate.cert.private_key_pem,
    cert = join("\n", [
      acme_certificate.cert.certificate_pem,
      acme_certificate.cert.issuer_pem,
    ])
  })
}
