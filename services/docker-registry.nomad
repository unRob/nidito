job "docker-registry" {
  datacenters = ["brooklyn"]
  type = "service"

  meta {
    reachability = "private"
  }

  vault {
    policies = ["docker-registry"]

    change_mode   = "signal"
    change_signal = "SIGHUP"
  }

  group "registry" {

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


    task "registry" {
      driver = "docker"

      constraint {
        attribute = "${meta.nidito-storage}"
        value     = "primary"
      }

      template {
        destination = "local/config.yml"
        data = <<EOF
version: 0.1
log:
  accesslog:
    disabled: true

storage:
  filesystem:
    rootdirectory: /var/lib/registry
  maintenance:
    uploadpurging:
      enabled: true
      age: 672h
      interval: 12h
      dryrun: false
    delete:
      enabled: true

http:
  addr: :5000
  {{ with secret "kv/nidito/config/dns" }}
  host: https://registry.{{ .Data.zone }}
  {{ end }}
  secret: averysecuresecret
  debug:
    addr: :5001
    prometheus:
      enabled: true

EOF
      }

      config {
        image = "registry:2.7"

        port_map {
          http = 5000
          metrics = 5001
        }

        volumes = [
          "/nidito/docker-registry:/var/lib/registry",
          "local/config.yml:/etc/docker/registry/config.yml",
        ]
      }

      resources {
        cpu    = 100
        memory = 128
        network {
          mbits = 10
          port "http" {}
          port "metrics" {}
        }
      }

      service {
        name = "registry-metrics"
        port = "metrics"

        tags = [
          "nidito.infra",
          "nidito.metrics.enabled",
        ]

        check {
          name     = "alive"
          type     = "tcp"
          interval = "60s"
          timeout  = "5s"
        }
      }

      service {
        name = "registry"
        port = "http"
        tags = [
          "nidito.infra",
          "nidito.dns.enabled",
          "nidito.http.enabled",
        ]

        meta = {
          nidito-http-zone = "trusted"
        }

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
