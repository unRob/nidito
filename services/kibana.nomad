job "kibana" {
  datacenters = ["brooklyn"]
  type = "service"

  meta {
    reachability = "private"
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
        attribute = "${meta.hardware}"
        operator  = "="
        value     = "[[ consulKey "/nidito/config/nodes/xitle/hardware" ]]"
      }

      config {
        image = "docker.elastic.co/kibana/kibana:7.4.0"

        port_map {
          http = 5601
        }
      }

      env {
        "SERVER_NAME" = "kibana.[[ consulKey "/nidito/config/dns/zone" ]]"
        "ELASTICSEARCH_HOSTS" = "http://elasticsearch.[[ consulKey "/nidito/config/dns/zone" ]]"
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
          "traefik.enable=true",

          "traefik.http.routers.kibana.rule=Host(`kibana.[[ consulKey "/nidito/config/dns/zone" ]]`)",
          "traefik.http.routers.kibana.entrypoints=http,https",
          "traefik.http.routers.kibana.tls=true",
          "traefik.http.routers.kibana.middlewares=trusted-network@consul,http-to-https@consul",
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
