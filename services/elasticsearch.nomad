job "logs" {
  datacenters = ["brooklyn"]
  type = "service"

  meta {
    reachability = "private"
  }

  group "elasticsearch" {

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


    task "elasticsearch-daemon" {
      driver = "docker"

      constraint {
        attribute = "${meta.hardware}"
        operator  = "="
        value     = "dsm918+"
      }

      config {
        image = "docker.elastic.co/elasticsearch/elasticsearch:7.4.0"

        port_map {
          http = 9200
          tcp = 9300
        }

        volumes = [
          "/docker/elasticsearch/data:/usr/share/elasticsearch/data"
        ]
      }

      template {
        data = <<EOF
        AUDIENCE="{{ key /nidito/config/networks/management }},{{ key /nidito/config/networks/vpn }}"
        EOF

        destination = "secrets/file.env"
        env         = true
      }

      env {
        "cluster.name" = "nidito"
        "bootstrap.memory_lock" = "true"
        "discovery.type" = "single-node"
        "ES_JAVA_OPTS" = "-Xms256m -Xmx256m"
      }

      resources {
        cpu    = 200
        memory = 800
        network {
          mbits = 10
          port "http" {}
          port "tcp" {
            static = 9200
          }
        }
      }

      service {
        name = "elasticsearch"
        port = "http"
        tags = [
          "infra",
          "nidito.dns.enabled",
          "traefik.enable=true",
          "traefik.protocol=http",
          "traefik.frontend.entryPoints=http",
          "traefik.frontend.whiteList.sourceRange=${ env.AUDIENCE }",
          "traefik.frontend.passHostHeader=false",
          "traefik.frontend.whiteList.useXForwardedFor=true"
        ]
        check {
          name     = "alive"
          type     = "tcp"
          interval = "30s"
          timeout  = "5s"
        }
      }

      service {
        name = "elasticsearch-api"
        port = "tcp"
        tags = [
          "infra",
          "traefik.enable=false",
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
