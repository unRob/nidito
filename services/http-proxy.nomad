job "http-proxy" {
  datacenters = ["brooklyn"]
  type = "service"

  meta {
    reachability = "public"
  }

  group "http-proxy" {
    reschedule {
      delay          = "5s"
      delay_function = "fibonacci"
      max_delay      = "1h"
      unlimited      = true
    }

    restart {
      # on failure, restart at most
      attempts = 10
      # during
      interval = "5m"
      # waiting after a crash
      delay = "25s"
      # after which, continue waiting `interval` units
      # before retrying
      mode = "delay"
    }


    task "traefik" {
      driver = "docker"

      template {
        data = <<EOF
CONSUL_HTTP_TOKEN="{{ key "/nidito/service/traefik/consul/token" }}"
DO_AUTH_TOKEN="{{ key "/nidito/config/dns/external/provider/token" }}"
EOF
        destination = "secrets/file.env"
        env         = true
      }

      template {
        data = <<EOF
[log]
  level = "INFO"

[certificatesResolvers.le.acme]
  email = "{{ key "/nidito/config/dns/external/email" }}"
  storage = "/acme/acme.json"

  [certificatesResolvers.le.acme.dnsChallenge]
    provider = "{{ key "/nidito/config/dns/external/provider/name" }}"
    resolvers = {{ key "/nidito/config/dns/external/forwarders/_json" }}

[entrypoints]
  [entrypoints.http]
    address = ":80"

  [entrypoints.https]
    address = ":443"
  [entryPoints.https.http.tls]
    certResolver = "le"

[ping]

[api]
  dashboard=true

[metrics]
  [metrics.prometheus]
    entryPoint = "traefik"

# Store the rest of the config in consul
[providers.consul]
  endpoints = ["http://consul.service.consul:{{ key "/nidito/config/consul/ports/http" }}"]

# Expose consul catalog services
[providers.consulCatalog]
  exposedByDefault = false
  defaultRule = "Host(`{{ .Name }}.{{ key "/nidito/config/dns/zone" }}`)"

  [providers.consulCatalog.endpoint]
    address = "http://consul.service.consul:{{ key "/nidito/config/consul/ports/http" }}"
EOF
        destination = "local/traefik.toml"
      }

      # Run wherever is tagged public
      constraint {
        attribute = "${meta.reachability}"
        operator  = "="
        value     = "public"
      }

      config {
        image = "traefik:v2.2.0"

        port_map {
          http = 80
          metrics = 81
          https = 443
          api = 8080
        }

        labels {
          "co.elastic.logs/module" = "traefik"
        }

        volumes = [
          "local/traefik.toml:/etc/traefik/traefik.toml",
          "/nidito/http-proxy/acme:/acme",
        ]
      }

      resources {
        cpu    = 100
        memory = 128
        network {
          mbits = 10
          port "http" {
            static = 80
          }
          port "metrics" {
            static = 81
          }
          port "https" {
            static = 443
          }
          port "api" {}
        }
      }

      service {
        name = "traefik"
        port = "api"

        tags = [
          "nidito.infra",
          "nidito.dns.enabled",
          "nidito.metrics.enabled",
          "nidito.metrics.port=81",
          "traefik.enable=true",

          "traefik.http.routers.traefik.rule=Host(`traefik.[[ consulKey "/nidito/config/dns/zone" ]]`)",
          "traefik.http.routers.traefik.entrypoints=http,https",
          "traefik.http.routers.traefik.tls=true",
          "traefik.http.routers.traefik.tls.certresolver=le",
          "traefik.http.routers.traefik.tls.domains[0].main=[[ consulKey "/nidito/config/dns/zone" ]]",
          "traefik.http.routers.traefik.tls.domains[0].sans=*.[[ consulKey "/nidito/config/dns/zone" ]]",
          "traefik.http.routers.traefik.service=api@internal",

          "traefik.http.routers.traefik.middlewares=trusted-network@consul,https-only@consul",
        ]

        check {
          type     = "http"
          path     = "/ping"
          interval = "10s"
          timeout  = "2s"
        }
      }

    }
  }
}
