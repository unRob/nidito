job "http-proxy" {
  datacenters = ["brooklyn"]
  type = "service"

  meta {
    reachability = "public"
  }

  group "http-proxy" {

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


    task "traefik" {
      driver = "docker"

      template {
        data = <<EOF
CONSUL_HTTP_TOKEN="{{key "/traefik/env/CONSUL_HTTP_TOKEN"}}"
DO_AUTH_TOKEN="{{key "/traefik/env/DO_AUTH_TOKEN"}}"
AUDIENCE="{{ key /nidito/config/networks/management }},{{ key /nidito/config/networks/vpn }}"
EOF
        destination = "secrets/file.env"
        env         = true
      }

      constraint {
        attribute = "${meta.reachability}"
        operator  = "="
        value     = "public"
      }

      config {
        image = "traefik:v1.7"

        args = []

        port_map {
          http = 80
          https = 443
          api = 8080
        }

        labels {
          "co.elastic.logs/module" = "traefik"
        }

        // disabled once config is loaded into consul
        // volumes = [
        //   "/docker/http-proxy/config:/etc/traefik"
        // ]
      }

      resources {
        cpu    = 100
        memory = 128
        network {
          mbits = 10
          port "http" {
            static = 80
          }
          port "https" {
            static = 443
          }
          port "api" {}
        }
      }

      service {
        name = "https-proxy"
        port = "https"
        tags = [
          "public", "edge"
        ]
        // TODO: enable when i figure out minio
        // check {
        //   type     = "http"
        //   path     = "/"
        //   interval = "10s"
        //   timeout  = "2s"
        // }
      }

      service {
        name = "http-proxy"
        port = "http"

        // TODO: enable when i figure out minio
        // check {
        //   type     = "http"
        //   path     = "/"
        //   interval = "10s"
        //   timeout  = "2s"
        // }
      }

      service {
        name = "traefik"
        port = "api"

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
          type     = "http"
          path     = "/ping"
          interval = "10s"
          timeout  = "2s"
        }
      }

    }
  }
}
