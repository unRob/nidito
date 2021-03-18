job "cajon" {
  datacenters = ["casa"]
  priority = 80

  group "cajon" {
    restart {
      attempts = 20
      interval = "20m"
      delay = "5s"
      mode = "delay"
    }

    network {
      port "http" {}
    }

    task cajon {
      driver = "docker"

      vault {
        policies = ["minio"]

        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      constraint {
        attribute = "${meta.nidito-storage}"
        value     = "primary"
      }

      template {
        destination = "secrets/environment"
        env = true
        data = <<ENV
{{- with secret "kv/nidito/config/services/minio" }}
MINIO_ACCESS_KEY={{ .Data.key }}
MINIO_SECRET_KEY={{ .Data.secret }}
{{ end }}
ENV
      }

      config {
        image = "minio/minio"
        args = [
          "gateway",
          "nas",
          "/data",
          "--address",
          ":${NOMAD_PORT_http}",
        ]

        ports = ["http"]

        volumes = [
          "/nidito/cajon:/data",
        ]
      }

      resources {
        cpu    = 30
        memory = 256
      }

      service {
        name = "cajon"
        port = "http"

        tags = [
          "nidito.dns.enabled",
          "nidito.http.enabled",
          "nidito.http.public",
        ]

        meta = {
          nidito-acl = "allow external"
          nidito-http-buffering = "off"
        }

        check {
          type     = "http"
          path     = "/minio/health/live"
          interval = "60s"
          timeout  = "2s"
        }
      }
    }
  }
}
