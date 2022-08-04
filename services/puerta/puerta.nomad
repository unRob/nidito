job "puerta" {
  datacenters = ["casa"]
  priority = 10

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
      port "http" {}
    }

    task "puerta" {
      driver = "docker"
      user = "nobody"

      vault {
        policies = ["puerta"]

        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        destination = "secrets/users.json"
        data = file("user-template.json.tpl")
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        destination = "secrets/env"
        env = true
        data = <<-ENV
          {{- with secret "nidito/service/puerta/config" }}
          PUERTA_ADAPTER="{{ .DATA.adapter }}"
          PUERTA_ENDPOINT="{{ .DATA.endpoint }}"
          {{ end }}
          {{- with secret "nidito/config/services/dns" }}
          PUERTA_REALM="puerta.{{ .Data.zone }}"
          {{ end }}
          {{- with secret "nidito/service/puerta/consul" }}
          CONSUL_HTTP_TOKEN={{ .DATA.token }}
          {{ end }}
          CONSUL_HTTP_ADDR={{ env "CONSUL_HTTP_ADDR" }}
        ENV
      }

      config {
        image = "registry.nidi.to/puerta:202205040531"
        ports = ["http"]

        args = [
          "secrets/users.json"
        ]

        volumes = [
          "secrets/users.json:/secrets/users.json",
        ]
      }

      resources {
        cpu    = 50
        memory = 128
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
          nidito-http-rate-limit = "10r/m"
          nidito-http-rate-limit-burst = "10r/m"
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
