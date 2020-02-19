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

      constraint {
        attribute = "${meta.hardware}"
        operator  = "="
        value     = "dsm918+"
      }

      template {
        data = <<EOF
        AUDIENCE="{{ key /nidito/config/networks/management }},{{ key /nidito/config/networks/vpn }}"
        EOF

        destination = "secrets/file.env"
        env         = true
      }

      config {
        image = "registry:2.7"

        port_map {
          http = 80
        }

        volumes = [
          "/docker/registry/data:/var/lib/registry",
          "/docker/registry/config:/etc/docker/registry/"
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
          "infra",
          "nidito.dns.enabled",
          "traefik.enable=true",
          "traefik.protocol=http",
          "traefik.frontend.entryPoints=http,https",
          "traefik.frontend.redirect.entryPoint=https",
          "traefik.frontend.passHostHeader=false",
          "traefik.frontend.whiteList.sourceRange=${ env.AUDIENCE }",
          "traefik.frontend.whiteList.useXForwardedFor=true"
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
