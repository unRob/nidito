job "docker-registry" {
  datacenters = ["brooklyn"]
  type = "service"

  meta {
    reachability = "private"
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

      # run on NAS
      constraint {
        attribute = "${meta.hardware}"
        operator  = "="
        value     = "[[ consulKey "/nidito/config/nodes/chapultepec/hardware" ]]"
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
  host: https://registry.[[ consulKey "/nidito/config/dns/zone" ]]
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
          "/nidito/data/docker-registry:/var/lib/registry",
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
          "traefik.enable=true",

          "traefik.http.routers.registry.rule=Host(`registry.[[ consulKey "/nidito/config/dns/zone" ]]`)",
          "traefik.http.routers.registry.entrypoints=http,https",
          "traefik.http.routers.registry.tls=true",
          "traefik.http.routers.registry.middlewares=trusted-network@consul,https-only@consul",
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
