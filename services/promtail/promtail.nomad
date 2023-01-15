job "promtail" {
  datacenters = ["casa"]
  type = "system"

  vault {
    policies = ["promtail"]
    change_mode   = "restart"
  }

  group "promtail" {
    network {
      port "http" {
        to = 3200
      }
    }

    restart {
      attempts = 3
      delay    = "20s"
      mode     = "delay"
    }

    task "promtail" {
      driver = "docker"

      env {
        HOSTNAME = "${attr.unique.hostname}"
      }

      template {
        destination = "secrets/tls/ca.pem"
        data = <<-PEM
        {{- with secret "cfg/infra/tree/service:ca" }}
        {{ .Data.cert }}
        {{- end }}
        PEM
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        data = file("promtail.yml")
        perms = 640
        destination = "/local/promtail.yml"
      }

      config {
        image = "grafana/promtail:demo"
        ports = ["http"]
        args = [
          "-config.file=/local/promtail.yml",
          "-server.http-listen-port=${NOMAD_PORT_http}",
        ]
        volumes = [
          "/var/lib/vector/promtail:/data",
          "/var/lib/nomad/data/:/nomad/",
          "secrets/tls/ca.pem:/etc/ssl/certs/nidito.crt",
        ]
      }

      resources {
        cpu    = 50
        memory = 100
      }

      service {
        name = "promtail"
        port = "http"
        tags = [
          "nidito.infra",
          "nidito.metrics.enabled",
        ]

        meta {
          nidito-acl = "allow altepetl"
        }

        check {
          name     = "Promtail HTTP"
          type     = "http"
          path     = "/targets"
          interval = "5s"
          timeout  = "2s"

          check_restart {
            limit           = 2
            grace           = "60s"
            ignore_warnings = false
          }
        }
      }
    }
  }
}
