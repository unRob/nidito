variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "cajon" {
  datacenters = ["casa"]
  priority    = 80

  group "cajon" {
    restart {
      attempts = 20
      interval = "20m"
      delay    = "5s"
      mode     = "delay"
    }

    network {
      port "http" {
        host_network = "private"
      }
      port "admin" {
        host_network = "private"
      }
    }

    task "cajon" {
      driver = "docker"

      vault {
        policies = ["cajon"]

        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      constraint {
        attribute = "${meta.storage}"
        value     = "primary"
      }

      template {
        destination = "secrets/environment"
        env         = true
        data        = <<ENV
{{- with secret "cfg/svc/tree/nidi.to:cajon" }}
MINIO_ACCESS_KEY={{ .Data.key }}
MINIO_SECRET_KEY={{ .Data.secret }}
{{ end }}
ENV
      }

      config {
        image = "minio/minio:RELEASE.2022-10-24T18-35-07Z"
        args = [
          "gateway",
          "nas",
          "/data",
          "--address",
          ":${NOMAD_PORT_http}",
          "--console-address",
          ":${NOMAD_PORT_admin}"
        ]

        ports = ["http", "admin"]

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

        meta {
          nidito-acl            = "allow external"
          nidito-http-buffering = "off"
          // needs to allow file uploads
          nidito-http-max-body-size = "500m"
        }

        check {
          type     = "http"
          path     = "/minio/health/live"
          interval = "60s"
          timeout  = "2s"
        }
      }

      service {
        name = "minio"
        port = "admin"

        tags = [
          "nidito.dns.enabled",
          "nidito.http.enabled",
        ]

        meta {
          nidito-acl            = "allow altepetl"
          nidito-http-buffering = "off"
        }

        // check {
        //   type     = "http"
        //   path     = "/minio/health/live"
        //   interval = "60s"
        //   timeout  = "2s"
        // }
      }
    }
  }
}
