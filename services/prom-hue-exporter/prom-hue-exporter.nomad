variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "prom-hue-exporter" {
  datacenters = ["casa"]
  region      = "casa"
  priority    = 10

  group "prom-hue-exporter" {
    reschedule {
      delay          = "5s"
      delay_function = "fibonacci"
      max_delay      = "1h"
      unlimited      = true
    }

    restart {
      attempts = 10
      interval = "10m"
      delay    = "10s"
      mode     = "delay"
    }

    network {
      port "http" {
        host_network = "private"
      }
    }

    constraint {
      // needs host ip to call hue
      attribute = "${meta.os_family}"
      operator  = "!="
      value     = "macos"
    }

    task "prom-hue-exporter" {
      driver = "docker"
      user   = "nobody"

      vault {
        role    = "prom-hue-exporter"
        change_mode = "restart"
      }

      template {
        destination = "/local/cgi-bin/metrics"
        perms       = 0777
        data        = file("./metrics")
      }

      resources {
        cpu        = 50
        memory     = 128
        memory_max = 512
      }

      config {
        image        = "${var.package.self.image}:${var.package.self.version}"
        ports        = ["http"]
        network_mode = "host"
        args = [
          "-h", "${NOMAD_TASK_DIR}",
          "-p", "${NOMAD_PORT_http}"
        ]
      }

      service {
        name = "prom-hue-exporter"
        port = "http"

        tags = [
          "nidito.service",
          "nidito.metrics.enabled",
          "nidito.metrics.path=/cgi-bin/metrics"
        ]

        meta {
          nidito-acl = "allow altepetl"
        }
      }

    }
  }
}
