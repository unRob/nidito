job "radio" {
  datacenters = ["casa"]
  priority = 50

  group "radio" {
    update {
      max_parallel = 1
    }

    reschedule {
      delay          = "5s"
      delay_function = "fibonacci"
      max_delay      = "1h"
      unlimited      = true
    }

    restart {
      attempts = 10
      interval = "10m"
      delay = "10s"
      mode = "delay"
    }

    network {
      port "http" {
        to = 8000
        static = 8000
        host_network = "private"
      }
    }

    task "radio" {
      driver = "docker"
      user = "icecast"

      vault {
        policies = ["icecast"]

        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      constraint {
        attribute = "${meta.storage}"
        value     = "primary"
      }

      identity {
        env = true
      }

      template {
        destination = "local/icecast.xml"
        data = file("icecast.xml")
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        destination = "secrets/minio-env.sh"
        data = file("minio-env.sh")
        perms = 0777
      }

      config {
        image = "registry.nidi.to/icecast:202304070642"
        ports = ["http"]

        volumes = [
          "local/icecast.xml:/etc/icecast.xml",
          "secrets/minio-env.sh:/home/icecast/minio-env.sh",
          "/nidito/icecast:/recordings"
        ]
      }

      resources {
        cpu    = 100
        memory = 128
      }

      service {
        name = "radio"
        port = "http"

        tags = [
          "nidito.service",
          "nidito.dns.enabled",
          "nidito.http.enabled",
          "nidito.http.public",
          "nidito.ingress.enabled",
        ]

        meta {
          nidito-acl = "allow external"
          nidito-http-buffering = "off"
        }

        check {
          type     = "http"
          path     = "/status.json"
          interval = "30s"
          timeout  = "2s"

          check_restart {
            limit = 10
            grace = "15s"
            ignore_warnings = false
          }
        }
      }

    }
  }
}
