job "docker-registry" {
  datacenters = ["casa"]
  type = "system"

  group "registry" {

    restart {
      # on failure, restart at most
      attempts = 20
      # during
      interval = "20m"
      # waiting after a crash
      delay = "5s"
      # after which, continue waiting `interval` units
      # before retrying
      mode = "delay"
    }

    network {
      port "http" {}
      port "metrics" {}
    }


    task "registry" {
      driver = "docker"

      vault {
        policies = ["docker-registry"]

        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      constraint {
        attribute = "${meta.storage}"
        value     = "primary"
      }

      template {
        destination = "local/config.yml"
        data = <<EOF
version: 0.1
log:
  accesslog:
    disabled: false

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
  addr: :{{ env "NOMAD_PORT_http" }}
  {{ with secret "cfg/infra/tree/service:dns" }}
  host: https://registry.{{ .Data.zone }}
  {{ end }}
  secret: averysecuresecret
  debug:
    addr: :{{ env "NOMAD_PORT_metrics" }}
    prometheus:
      enabled: true

EOF
      }

      config {
        image = "registry:2.7"

        ports = ["http", "metrics"]

        volumes = [
          "/nidito/docker-registry:/var/lib/registry",
          "local/config.yml:/etc/docker/registry/config.yml",
        ]
      }

      resources {
        cpu    = 100
        memory = 128
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

        meta {
          nidito-acl = "allow altepetl"
          nidito-http-max-body-size = "700m"
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
