variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "event-gateway" {
  datacenters = ["casa"]
  region      = "casa"

  group "event-gateway" {
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
      delay    = "10s"
      mode     = "delay"
    }

    network {
      port "http" {
        host_network = "private"
      }
    }

    task "event-gateway" {
      driver = "docker"

      vault {
        role = "event-gateway"
        change_mode   = "restart"
      }

      template {
        destination   = "local/listeners.json"
        data          = file("./listeners.json.tpl")
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        destination = "secrets/env"
        env         = true
        data        = <<ENV
          LOG_LEVEL="debug"
          LISTENERS_PATH="{{ env "NOMAD_TASK_DIR" }}/listeners.json"
          PORT="{{ env "NOMAD_PORT_http" }}"
          NOMAD_ADDR="unix://{{ env "NOMAD_SECRETS_DIR" }}/api.sock"
          NOMAD_TOKEN="{{ with secret "nomad/creds/service-event-gateway" }}{{ .Data.secret_id }}{{ end }}"
        ENV
      }

      identity {
        env  = false
        file = true
      }

      config {
        image        = "${var.package.self.image}:${var.package.self.version}"
        ports        = ["http"]
        network_mode = "bridge"
      }

      resources {
        cpu        = 50
        memory     = 128
        memory_max = 512
      }

      service {
        name = "event-gateway"
        port = "http"

        tags = [
          "nidito.service",
          "nidito.dns.enabled",
          "nidito.http.enabled",
          "nidito.http.public",
          "nidito.ingress.enabled",
        ]

        meta {
          nidito-acl            = "allow external"
          nidito-http-buffering = "off"
          nidito-dns-alias      = "evgw"
          // nidito-http-rate-limit = "60r/m"
          // nidito-http-rate-limit-total = "120"
        }

        check {
          type     = "tcp"
          interval = "30s"
          timeout  = "2s"

          check_restart {
            limit           = 10
            grace           = "15s"
            ignore_warnings = false
          }
        }
      }
    }
  }
}
