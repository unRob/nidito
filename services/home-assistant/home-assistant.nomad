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

    # volume "home-assistant-config" {
    #   type            = "csi"
    #   source          = "home-assistant-config"
    #   attachment_mode = "file-system"
    #   access_mode     = "multi-node-multi-writer"
    # }

    volume "home-assistant-config" {
      type   = "host"
      source = "home-assistant"
    }

    task "home-assistant" {
      vault {
        role = "home-assistant"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      constraint {
        attribute = "${attr.unique.hostname}"
        # s3 backing for storage hasn't worked all that well, so pick a host and figure outo backups later
        value     = "guerrero"
      }

      driver = "docker"

      resources {
        cpu = 1000
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

      template {
        destination   = "local/configuration.yaml"
        data          = file("./configuration.yaml")
        gid           = 1002
        perms         = 660
        change_mode   = "restart"
      }

      template {
        destination   = "local/install-ca.sh"
        data          = file("./install-ca.sh")
        change_mode   = "restart"
        gid           = 1002
        perms         = 770
      }

      template {
        destination   = "local/backup-sync.sh"
        data          = file("./backup-sync.sh")
        change_mode   = "noop"
        gid           = 1002
        perms         = 770
      }

      template {
        destination   = "secrets/backup-credentials.sh"
        data          = file("./backup-credentials.sh")
        change_mode   = "noop"
        gid           = 1002
      }

      config {
        image = "${var.package.self.image}:${var.package.self.version}"
        ports = ["http"]
        # needs zeroconf and shit
        network_mode = "host"
        volumes = [
          "secrets/secrets.yaml:/config/secrets.yaml",
          "local/configuration.yaml:/config/configuration.yaml",
          # https://github.com/just-containers/s6-overlay?tab=readme-ov-file#executing-initialization-and-finalization-tasks
          "local/install-ca.sh:/etc/cont-init.d/install-ca.sh",
          # enable bluetooth device control
          "/run/dbus:/run/dbus:ro"
        ]
        privileged = true
        group_add = ["1002"]
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

      action "sync-backups" {
        command = "/local/sync-backups.sh"
      }
    }
  }
}
