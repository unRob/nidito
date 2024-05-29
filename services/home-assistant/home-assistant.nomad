variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "home-assistant" {
  datacenters = ["casa"]
  namespace   = "home"

  group "home-assistant" {
    restart {
      delay = "15s"
      attempts = 40
      interval = "10m"
      mode = "delay"
    }

    network {
      port "http" {
      }
    }

    volume "home-assistant-config" {
      type            = "csi"
      source          = "home-assistant-config"
      attachment_mode = "file-system"
      access_mode     = "multi-node-multi-writer"
    }

    task "home-assistant" {
      vault {
        role = "home-assistant"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      constraint {
        attribute = "${meta.os_family}"
        operator  = "!="
        # haven't gotten CSI to work on macos
        value     = "macos"
      }

      driver = "docker"

      resources {
        cpu = 50
        memory = 512
        memory_max = 1024
      }

      volume_mount {
        volume      = "home-assistant-config"
        destination = "/config"
      }

      template {
        destination   = "secrets/secrets.yaml"
        data          = file("./secrets.yaml")
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      config {
        image = "${var.package.self.image}:${var.package.self.version}"
        ports = ["http"]
        # needs zeroconf and shit
        network_mode = "host"
        volumes = [
          "secrets/secrets.yaml:/config/secrets.yaml"
        ]
        privileged = true
      }

      service {
        name = "control"
        port = "http"

        check {
          type     = "tcp"
          interval = "60s"
          timeout  = "2s"
        }

        tags = [
          "nidito.dns.enabled",
          "nidito.http.enabled",
          "nidito.metrics.enabled",
          "nidito.metrics.path=/api/prometheus",
        ]

        meta {
          nidito-acl = "allow robotitos,altepetl"
          nidito-http-buffering = "off"
          nidito-http-wss = "on"
        }
      }
    }
  }
}
