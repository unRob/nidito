terraform {
  required_providers {
    acme = {
      source = "vancluever/acme"
       version = "~> 2.5.3"
    }
  }

  required_version = ">= 1.0"
}

locals {
  kv_prefix = "nidito/tls/${var.dns_zone}"
  do_config = {
    DO_AUTH_TOKEN = var.do_token
    DO_PROPAGATION_TIMEOUT = 60
    DO_TTL = 30
  }
}

resource acme_certificate main-cert {
  account_key_pem           = var.acme_account_key_pem
  common_name               = var.dns_zone
  subject_alternative_names = ["*.${var.dns_zone}"]

  recursive_nameservers = ["1.1.1.1:53", "8.8.8.8:53"]

  dns_challenge {
    provider = "digitalocean"
    config = local.do_config
  }
}

resource vault_generic_secret main-cert {
  path = "${local.kv_prefix}/main"
  data_json = jsonencode({
    private_key = acme_certificate.main-cert.private_key_pem,
    cert = join("\n", [
      acme_certificate.main-cert.certificate_pem,
      acme_certificate.main-cert.issuer_pem,
    ])
    issuer = acme_certificate.main-cert.issuer_pem,
    bare_cert = acme_certificate.main-cert.certificate_pem,
  })
}
