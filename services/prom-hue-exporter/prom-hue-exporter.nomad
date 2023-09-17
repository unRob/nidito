job "prom-hue-exporter" {
  datacenters = ["casa"]
  region      = "casa"
  priority    = 10

  vault {
    policies    = ["prom-hue-exporter"]
    change_mode = "restart"
  }

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

      template {
        destination = "/local/metrics"
        perms       = 0777
        data        = file("./metrics")
      }

      resources {
        cpu        = 50
        memory     = 128
        memory_max = 512
      }

      config {
        image        = "registry.nidi.to/prom-hue-exporter:202305030550"
        ports        = ["http"]
        network_mode = "host"
        args = [
          "-d", "${NOMAD_TASK_DIR}",
          "-p", "${NOMAD_PORT_http}",
          "-c", "metrics",
        ]
      }

      service {
        name = "prom-hue-exporter"
        port = "http"

        tags = [
          "nidito.service",
          "nidito.metrics.enabled"
        ]

        meta {
          nidito-acl = "allow altepetl"
        }
      }

    }
  }
}
