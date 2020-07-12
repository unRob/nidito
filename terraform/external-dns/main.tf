terraform {
  backend "consul" {
    path    = "nidito/state/external-dns"
  }

  required_version = ">= 0.12.20"
}

provider digitalocean {
  token = data.consul_key_prefix.cfg.subkeys["dns/external/provider/token"]
}

data consul_key_prefix cfg {
  path_prefix = "/nidito/config"
}

resource digitalocean_domain root {
  name       = data.consul_key_prefix.cfg.subkeys["dns/zone"]
}

resource digitalocean_record txt_root {
  domain = digitalocean_domain.root.name
  type   = "TXT"
  name   = "@"
  value  = "v=spf1 include:mailgun.org ~all;"
}
