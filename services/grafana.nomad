job "grafana" {
  datacenters = ["brooklyn"]
  type        = "service"



  group "grafana" {
    reschedule {
      delay          = "5s"
      delay_function = "fibonacci"
      max_delay      = "1h"
      unlimited      = true
    }

     restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    task "grafana" {
      driver = "docker"

      constraint {
        attribute = "${meta.hardware}"
        operator  = "="
        value     = "[[ consulKey "/nidito/config/nodes/xitle/hardware" ]]"
      }

      env {
        GF_INSTALL_PLUGINS = "grafana-piechart-panel"
      }

      config {
        image = "grafana/grafana"

        port_map {
          http = 3000
        }


        volumes = [
          "/nidito/grafana/data:/var/lib/grafana"
        ]
      }

      resources {
        cpu    = 50
        memory = 128

        network {
          mbits = 1
          port  "http" {}
        }
      }

      service {
        name = "grafana"
        port = "http"

        tags = [
          "nidito.infra",
          "nidito.dns.enabled",
           "nidito.metrics.enabled",
          "traefik.enable=true",

          "traefik.http.routers.grafana.rule=Host(`grafana.[[ consulKey "/nidito/config/dns/zone" ]]`)",
          "traefik.http.routers.grafana.entrypoints=http,https",
          "traefik.http.routers.grafana.tls=true",
          "traefik.http.routers.grafana.middlewares=trusted-network@consul,https-only@consul",
        ]

        check {
          type     = "http"
          path     = "/health"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
