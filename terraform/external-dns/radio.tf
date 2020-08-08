resource digitalocean_record radio {
  domain = digitalocean_domain.root.name
  type   = "CNAME"
  name   = "radio"
  ttl = 3600
  value  = "${digitalocean_domain.root.name}."
}
