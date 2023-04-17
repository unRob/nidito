job "grafana" {
  datacenters = ["casa"]
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

    network {
      port "http" {
        to = 3000
        host_network = "private"
      }
    }

    task "grafana" {
      driver = "docker"

      constraint {
        attribute = "${meta.storage}"
        value     = "secondary"
      }

      env {
        GF_INSTALL_PLUGINS = "grafana-piechart-panel"
        GF_DOMAIN_ROOT_URL = "https://grafana.nidi.to"
        // GF_PATHS_CONFIG = "/secrets/grafana.ini"
      }

      config {
        image = "grafana/grafana:9.4.7"
        ports = ["http"]
        volumes = [
          "/nidito/grafana/data:/var/lib/grafana"
        ]
      }

      resources {
        cpu    = 100
        memory = 200
        memory_max = 500
      }

      service {
        name = "grafana"
        port = "http"

        tags = [
          "nidito.infra",
          "nidito.dns.enabled",
          "nidito.metrics.enabled",
          "nidito.http.enabled",
          "nidito.logs.enabled",
        ]

        meta {
          nidito-acl = "allow altepetl"
          nidito-http-buffering = "off"
          nidito-http-wss = "on"
          nidito-http-max-body-size = "10m"
        }

        check {
          type     = "http"
          path     = "/healthz"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
