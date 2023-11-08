job "prometheus" {
  datacenters = ["casa"]
  type        = "service"

  vault {
    policies    = ["prometheus"]
    change_mode = "restart"
  }

  group "prometheus" {
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
        static       = 9090
        host_network = "private"
      }
    }

    task "prometheus" {
      driver = "docker"

      constraint {
        attribute = "${meta.storage}"
        value     = "primary"
      }

      template {
        destination   = "secrets/tls/ca.pem"
        data          = <<-PEM
        {{- with secret "cfg/infra/tree/service:ca" }}
        {{ .Data.cert }}
        {{- end }}
        PEM
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        change_mode = "restart"
        data        = file("config.yaml.tpl")
        destination = "local/prometheus.yml"
      }

      config {
        image        = "prom/prometheus:v2.47.2"
        ports        = ["http"]
        network_mode = "host"

        volumes = [
          "/nidito/prometheus:/var/lib/prometheus",
          "secrets/tls/ca.pem:/etc/ssl/certs/nidito.crt",
        ]

        args = [
          "--config.file=/local/prometheus.yml",
          "--storage.tsdb.path=/var/lib/prometheus/fresh",
          "--storage.tsdb.retention.time=90d",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
          "--web.enable-admin-api",
        ]
      }

      resources {
        cpu    = 200
        memory = 500
      }

      service {
        name = "prometheus"
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
          port     = "http"
          path     = "/targets"
          interval = "10s"
          timeout  = "2s"
        }
      }


    }
  }
}
