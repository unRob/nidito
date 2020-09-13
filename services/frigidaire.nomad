job "frigidaire" {
  datacenters = ["brooklyn"]
  type = "service"
  priority = 40

  meta {
    reachability = "public"
  }

  vault {
    policies = ["frigidaire"]

    change_mode   = "signal"
    change_signal = "SIGHUP"
  }

  group "frigidaire" {

    restart {
      # on failure, restart at most
      attempts = 10
      # during
      interval = "5m"
      # waiting after a crash
      delay = "25s"
      # after which, continue waiting `interval` units
      # before retrying
      mode = "delay"
    }


    task "hc-frigidaire" {
      driver = "raw_exec"

      constraint {
        attribute = "${meta.arch}"
        value     = "Darwin"
      }

      artifact {
        source      = "https://github.com/nidi-to/hc-frigidaire/releases/download/v0.0.0/hc-frigidaire-${attr.kernel.name}-${attr.cpu.arch}.tgz"
      }

      template {
        data = <<JSON
{{- with secret "kv/nidito/config/services/frigidaire" }}
FRIGIDAIRE_USERNAME="{{ .Data.email }}"
FRIGIDAIRE_PASSWORD="{{ .Data.password }}"
HC_PORT="{{ env "NOMAD_PORT_http" }}"
HC_PATH="/nidito/hc-frigidaire/data"
{{- end }}
JSON
        destination = "secrets/file.env"
        change_mode = "restart"
        env = true
      }

      config {
        command = "local/hc-frigidaire-${attr.kernel.name}-${attr.cpu.arch}"
      }

      resources {
        cpu    = 50
        memory = 32
        network {
          mbits = 10
          port "http" {}
        }
      }

      service {
        name = "hc-frigidaire"
        port = "http"

        tags = [
          "nidito.service",
        ]

        check {
          name     = "alive"
          type     = "tcp"
          interval = "60s"
          timeout  = "5s"
        }
      }
    }
  }
}
