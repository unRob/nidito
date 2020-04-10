provider nomad {}
provider consul {}


data consul_key_prefix cfg {
  path_prefix = "/nidito/config"
}

resource consul_acl_policy service-traefik {
  name        = "service-traefik"
  description = "traefik policy"
  datacenters = ["brooklyn"]
  rules       = <<-RULE
    service "traefik" {
      policy = "write"
    }
    service_prefix "" {
      policy = "read"
    }
    node_prefix "" {
      policy = "read"
    }
    key_prefix "traefik" {
      policy = "write"
    }
    key_prefix "nidito/service/traefik/" {
      policy = "read"
    }
    session_prefix "" {
      policy = "write"
    }
    key "traefik" {
      policy = "write"
    }
    RULE
}

resource consul_acl_token service-traefik {
  description = "traefik"
  policies = [ consul_acl_policy.service-traefik.name ]
  local = false
}

data consul_acl_token_secret_id service-traefik {
  accessor_id = "${consul_acl_token.service-traefik.id}"
}


resource consul_key_prefix "service-traefik-config" {
  datacenter = "brooklyn"

  # Prefix to add to prepend to all of the subkey names below.
  path_prefix = "nidito/service/traefik/"

  subkeys = {
    "consul/token"  = data.consul_acl_token_secret_id.service-traefik.secret_id
  }
}

// Traefik manages the rest of these, so we can't use
// consul_key_prefix for that, as the rest of the keys would be deleted :(
locals {
  service-config = {
    "log/level" = "info"
    ping = "true"
    "api/dashboard" = "true"

    "metrics/prometheus/entryPoint" = "https"

    "providers/consulCatalog/exposedByDefault" = "false"
    "providers/consulCatalog/defaultRule" = "Host(`{{ .Name }}.${data.consul_key_prefix.cfg.subkeys["dns/zone"]}`)"
    "providers/consulCatalog/endpoint/address" = "http://consul.service.consul:${data.consul_key_prefix.cfg.subkeys["consul/ports/http"]}"

    # catch all single word domains (because domain-search) and re-route to fqdn https
    "http/routers/bare-to-fqdn/rule" = "HostRegexp(`{host:^([^.]+)$}`)"
    "http/routers/bare-to-fqdn/entryPoints/0" = "http"
    "http/routers/bare-to-fqdn/middlewares/0" = "http-to-https"
    "http/routers/bare-to-fqdn/service" = "noop"
    "http/services/noop/loadBalancer/servers/0/url" = "http://192.0.2.1"
    # usage: http-to-https@consul
    "http/middlewares/http-to-https/redirectregex/regex" = "^https?://([^/]+)/?(.*)?$"
    "http/middlewares/http-to-https/redirectregex/replacement" = "https://$1.${data.consul_key_prefix.cfg.subkeys["dns/zone"]}/$2"
    "http/middlewares/http-to-https/redirectregex/permanent" = "true"
    # usage: home-network@consul
    "http/middlewares/home-network/ipwhitelist/sourcerange" = join(",", [
      data.consul_key_prefix.cfg.subkeys["networks/management"],
      data.consul_key_prefix.cfg.subkeys["networks/local-network"],
      data.consul_key_prefix.cfg.subkeys["networks/vpn"]
    ])
    # usage: trusted-network@consul
    "http/middlewares/trusted-network/ipwhitelist/sourcerange" = join(",", [
      data.consul_key_prefix.cfg.subkeys["networks/management"],
      data.consul_key_prefix.cfg.subkeys["networks/vpn"]
    ])
    # usage: https-only@consul
    "http/middlewares/https-only/redirectscheme/scheme" = "https"
  }
}

resource consul_keys service-traefik {
  datacenter = "brooklyn"

  dynamic "key" {
    for_each = local.service-config
    content {
      path = "traefik/${key.key}"
      value = key.value
    }
  }
}
