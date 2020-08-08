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
      driver = "exec"

      constraint {
        attribute = "${meta.hardware}"
        value     = "mbp"
      }

      artifact {
        source      = "https://github.com/nidi-to/hc-frigidaire/releases/download/v0.0.0/hc-frigidaire-${attr.kernel.name}-${attr.cpu.arch}.tgz"
        destination = "local/hc-frigidaire"
      }

      template {
        data = <<JSON
{{- with secret "kv/nidito/config/services/frigidaire" }}
export FRIGIDAIRE_USERNAME="{{ .Data.email }}"
export FRIGIDAIRE_PASSWORD="{{ .Data.password }}"
export HC_PIN="{{ .Data.pin }}"
export HC_PORT="{{ env "NOMAD_PORT_hc-frigidaire" }}"
export HC_PATH="/nidito/hc-frigidaire/data"
{{- end }}
JSON
        destination = "secrets/file.env"
        change_mode = "restart"
        env = true
      }

      config {
        command = "local/hc-frigidaire"
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
