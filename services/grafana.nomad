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
      }
    }

    task "grafana" {
      driver = "docker"

      constraint {
        attribute = "${meta.hardware}"
        value     = "mbp"
      }

      env {
        GF_INSTALL_PLUGINS = "grafana-piechart-panel"
      }

      config {
        image = "grafana/grafana:7.5.4"
        ports = ["http"]
        volumes = [
          "/nidito/grafana/data:/var/lib/grafana"
        ]
      }

      resources {
        cpu    = 100
        memory = 256
      }

      service {
        name = "grafana"
        port = "http"

        tags = [
          "nidito.infra",
          "nidito.dns.enabled",
          "nidito.metrics.enabled",
          "nidito.http.enabled",
        ]

        meta {
          nidito-acl = "allow altepetl"
        }

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
