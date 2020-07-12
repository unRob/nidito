locals {
  mx_servers = {
    "mxa.mailgun.org." = 10,
    "mxb.mailgun.org." = 10,
  }
}

resource digitalocean_record txt_smtp_domainkey {
  domain = digitalocean_domain.root.name
  type   = "TXT"
  name   = "smtp._domainkey"
  value  = data.consul_key_prefix.cfg.subkeys["services/mailgun/domainkey"]
}

resource digitalocean_record mx_root {
  for_each = local.mx_servers
  domain = digitalocean_domain.root.name
  type   = "MX"
  name   = "@"
  value  = each.key
  priority = each.value
}

