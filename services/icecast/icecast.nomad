job "radio" {
  datacenters = ["casa"]
  priority = 50

  group "radio" {
    reschedule {
      delay          = "5s"
      delay_function = "fibonacci"
      max_delay      = "1h"
      unlimited      = true
    }

    restart {
      attempts = 10
      interval = "10m"
      delay = "10s"
      mode = "delay"
    }

    network {
      port "http" {
        to = 8000
        static = 8000
      }
    }

    task "radio" {
      driver = "docker"
      user = "icecast"

      vault {
        policies = ["icecast"]

        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      constraint {
        attribute = "${meta.storage}"
        value     = "primary"
      }

      template {
        destination = "local/icecast.xml"
        data = file("icecast.xml")
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        destination = "local/minio-env.sh"
        data = file("minio-env.sh")

        perms = "777"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      config {
        image = "registry.nidi.to/icecast:202112310439"

        ports = ["http"]

        volumes = [
          "local/icecast.xml:/etc/icecast.xml",
          "local/minio-env.sh:/home/icecast/minio-env.sh",
          "/nidito/icecast:/recordings"
        ]
      }

      resources {
        cpu    = 100
        memory = 128
      }

      service {
        name = "radio"
        port = "http"

        tags = [
          "nidito.service",
          "nidito.dns.enabled",
          "nidito.http.enabled",
          "nidito.http.public",
          "nidito.ingress.enabled",
        ]

        meta {
          nidito-acl = "allow external"
          nidito-http-buffering = "off"
        }

        check {
          type     = "http"
          path     = "/status.json"
          interval = "30s"
          timeout  = "2s"

          check_restart {
            limit = 10
            grace = "15s"
            ignore_warnings = false
          }
        }
      }

    }

    task "website-sync" {
      lifecycle {
        hook = "post-start"
      }

      driver = "docker"

      vault {
        policies = ["cdn"]
      }

      template {
        destination = "local/website-sync.sh"
        perms = 750
        data = file("entrypoint.sh")
      }

      template {
        destination = "secrets/file.env"
        env = true
        data = <<EOF
{{- with secret "nidito/config/services/dns" }}
{{- scratch.Set "zone" .Data.zone }}
{{- end }}
{{- with secret "nidito/config/services/minio" }}
MC_HOST_cajon="https://{{ .Data.key }}:{{ .Data.secret }}@cajon.{{ scratch.Get "zone" }}/"
{{- end }}
{{- with secret "nidito/config/services/cdn" }}
MC_HOST_cdn="https://{{ .Data.key }}:{{ .Data.secret }}@{{ .Data.endpoint }}/"
{{- end }}
EOF
      }

      config {
        image = "registry.nidi.to/base-sync:latest"
        command = "./local/entrypoint.sh"

        volumes = [
          "local/entrypoint.sh:/entrypoint.sh",
        ]
      }

      resources {
        cpu = 100
        memory = 300
      }
    }
  }
}
