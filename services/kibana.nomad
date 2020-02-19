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
        value     = "dsm918+"
      }

      config {
        image = "docker.elastic.co/kibana/kibana:7.4.0"

        port_map {
          http = 5601
        }
      }

      env {
        "SERVER_NAME" = "kibana.nidi.to"
        "ELASTICSEARCH_HOSTS" = "http://elasticsearch.nidi.to"
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
          "infra",
          "traefik.enable=true",
          "traefik.protocol=http",
          "traefik.frontend.entryPoints=https,http",
          "traefik.frontend.redirect.entryPoint=https",
          "traefik.frontend.passHostHeader=false",
          "traefik.frontend.whiteList.sourceRange=10.0.0.1/12",
          "traefik.frontend.whiteList.useXForwardedFor=true"
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
