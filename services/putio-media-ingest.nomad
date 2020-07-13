
job "putio-media-ingest" {
  datacenters = ["brooklyn"]
  type = "batch"
  priority = 10

  vault {
    policies = ["putio"]

    change_mode   = "signal"
    change_signal = "SIGHUP"
  }

  group "putio-media-ingest" {

    task "rclone" {
      driver = "docker"

      constraint {
        attribute = "${meta.nidito-storage}"
        value     = "primary"
      }

      env {
        TARGET = "/media"
      }

      template {
        data = <<EOF
[putio]
type = putio
{{ with secret "kv/nidito/service/putio" }}
token = {"access_token":"{{ .Data.token }}","expiry":"0001-01-01T00:00:00Z"}
{{ end }}
EOF
        destination = "local/rclone.conf"
      }

      config {
        image = "registry.nidi.to/putio-media-ingest:latest"

        volumes = [
          "local/rclone.conf:/config/rclone/rclone.conf",
          "/volume1/media/dropbox/:/media",
        ]
      }

      resources {
        cpu = 40
        memory = 800
        network {
          mbits = 100
        }
      }
    }
  }

}