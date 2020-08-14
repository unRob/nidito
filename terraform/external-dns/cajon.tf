resource digitalocean_record cajon {
  domain = digitalocean_domain.root.name
  type   = "CNAME"
  name   = "cajon"
  ttl = 3600
  value  = "${digitalocean_domain.root.name}."
}
