variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "grafana" {
  datacenters = ["casa"]
  type        = "service"
  namespace   = "infra-observability"

  group "grafana" {
    reschedule {
      delay          = "5s"
      delay_function = "fibonacci"
      max_delay      = "1h"
      unlimited      = true
    }

    restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }

    network {
      port "http" {
        to           = 3000
        host_network = "private"
      }
    }

    task "db-restore" {
      vault {
        role = "grafana"
        change_mode   = "restart"
      }
      lifecycle {
        hook = "prestart"
        sidecar = false
      }

      driver = "docker"
      user   = "nobody"

      resources {
        cpu        = 128
        memory     = 64
        memory_max = 512
      }

      config {
        image   = "${var.package.litestream.image}:${var.package.litestream.version}"
        args    = ["restore", "/alloc/grafana.db"]
        volumes = ["secrets/litestream.yaml:/etc/litestream.yml"]
      }

      template {
        data        = file("litestream.yaml")
        destination = "secrets/litestream.yaml"
      }
    }

    task "db-replicate" {
      vault {
        role = "grafana"
        change_mode   = "restart"
      }
      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      driver = "docker"
      user   = "nobody"

      resources {
        cpu        = 256
        memory     = 128
        memory_max = 512
      }

      config {
        image   = "${var.package.litestream.image}:${var.package.litestream.version}"
        args    = ["replicate"]
        volumes = ["secrets/litestream.yaml:/etc/litestream.yml"]
      }

      template {
        data        = file("litestream.yaml")
        destination = "secrets/litestream.yaml"
      }
    }

    task "grafana" {
      driver = "docker"
      user   = "nobody"

      vault {
        role = "grafana"
        change_mode   = "restart"
      }

      env {
        GF_DOMAIN_ROOT_URL = "https://grafana.${meta.dns_zone}"
        GF_DATABASE_TYPE = "sqlite3"
        GF_DATABASE_WAL = "true"
        GF_DATABASE_PATH = "/alloc/grafana.db"
        // GF_PATHS_CONFIG = "/secrets/grafana.ini"
      }

      config {
        image = "${var.package.self.image}:${var.package.self.version}"
        ports = ["http"]
      }

      resources {
        cpu        = 512
        memory     = 256
        memory_max = 512
      }

      service {
        name = "grafana"
        port = "http"

        tags = [
          "nidito.infra",
          "nidito.dns.enabled",
          "nidito.metrics.enabled",
          "nidito.http.enabled",
          "nidito.logs.enabled",
        ]

        meta {
          nidito-acl                = "allow altepetl"
          nidito-http-buffering     = "off"
          nidito-http-wss           = "on"
          nidito-http-max-body-size = "10m"
        }

        check {
          type     = "http"
          path     = "/healthz"
          interval = "10s"
          timeout  = "2s"
        }
      }
    }
  }
}
