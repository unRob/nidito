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

      config {
        image = "registry:2.7"

        port_map {
          http = 80
        }

        volumes = [
          "/nidito/registry/data:/var/lib/registry",
          "/nidito/registry/config:/etc/docker/registry/"
        ]
      }

      resources {
        cpu    = 100
        memory = 128
        network {
          mbits = 10
          port "http" {}
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
