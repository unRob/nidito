job "puerta" {
  datacenters = ["casa"]
  region = "casa"
  priority = 10

  vault {
    policies = ["puerta"]

    change_mode   = "signal"
    change_signal = "SIGHUP"
  }

  group "puerta" {
    update {
      max_parallel = 1
    }

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
        host_network = "private"
      }
    }

    task "db-restore" {
      lifecycle {
        hook = "prestart"
      }

      driver = "docker"
      user = "nobody"

      resources {
        cpu    = 128
        memory = 64
        memory_max = 512
      }

      config {
        image = "litestream/litestream:0.3.9"
        args = ["restore", "/alloc/puerta.db"]
        volumes = ["secrets/litestream.yaml:/etc/litestream.yml"]
      }

      template {
        data = file("litestream.yaml")
        destination = "secrets/litestream.yaml"
      }
    }

    task "db-replicate" {
      lifecycle {
        hook = "prestart"
        sidecar = true
      }

      driver = "docker"
      user = "nobody"

      resources {
        cpu    = 256
        memory = 128
        memory_max = 512
      }

      config {
        image = "litestream/litestream:0.3.9"
        args = ["replicate"]
        volumes = ["secrets/litestream.yaml:/etc/litestream.yml"]
      }

      template {
        data = file("litestream.yaml")
        destination = "secrets/litestream.yaml"
      }
    }

    task "puerta" {
      driver = "docker"
      user = "nobody"

      template {
        destination = "secrets/config.yaml"
        data = <<-ENV
          {{- with secret "cfg/svc/tree/nidi.to:puerta" }}
          name: Castillo de Chapultebob
          timezone: America/Mexico_City
          adapter:
            kind: hue
            username: {{ .Data.hue.key }}
            ip: {{ .Data.hue.bridge }}
            device: {{ .Data.hue.device }}
          http:
            listen: :{{ env "NOMAD_PORT_http" }}
            origin: puerta.nidi.to
            protocol: https
          push:
            key:
              private: {{ .Data.push.key.private }}
              public: {{ .Data.push.key.public }}
          {{ end }}
          {{- with secret "cfg/infra/tree/service:dns" }}
            origin: puerta.{{ .Data.zone }}
          {{- end -}}
        ENV
        change_mode = "noop"
      }

      config {
        image = "registry.nidi.to/puerta:202305310111"
        ports = ["http"]
        network_mode = "bridge"
        entrypoint = ["/bin/sh", "-c"]
        command = "puerta db migrate --config /secrets/config.yaml --db /alloc/puerta.db && puerta server --config /secrets/config.yaml --db /alloc/puerta.db"
      }

      resources {
        cpu    = 50
        memory = 128
        memory_max = 512
      }

      service {
        name = "puerta"
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
          nidito-http-rate-limit = "60r/m"
          nidito-http-rate-limit-burst = "20"
        }

        check {
          type     = "tcp"
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
  }
}
