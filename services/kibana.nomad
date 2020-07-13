job "kibana" {
  datacenters = ["brooklyn"]
  type = "service"

  meta {
    reachability = "private"
  }

  vault {
    policies = ["dns-update"]

    change_mode   = "signal"
    change_signal = "SIGHUP"
  }

  group "kibana" {

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

    task "kibana" {
      driver = "docker"

      constraint {
        attribute = "${meta.nidito-storage}"
        value     = "primary"
      }

      config {
        image = "docker.elastic.co/kibana/kibana:7.4.0"

        port_map {
          http = 5601
        }
      }

      template {
        data = <<EOF
{{ with secret "kv/nidito/config/dns" }}
SERVER_NAME="kibana.{{ .Data.zone }}"
ELASTICSEARCH_HOSTS="http://elasticsearch.{{ .Data.zone }}"
{{ end }}
EOF
        destination = "secrets/file.env"
        env         = true
      }

      resources {
        cpu    = 400
        memory = 512
        network {
          mbits = 10
          port "http" {}
        }
      }

      service {
        name = "kibana"
        port = "http"
        tags = [
          "nidito.infra",
          "nidito.dns.enabled",
          "nidito.http.enabled",
          "nidito.http.zone=trusted",
        ]
        check {
          name     = "alive"
          type     = "tcp"
          interval = "30s"
          timeout  = "5s"
        }
      }
    }
  }
}
