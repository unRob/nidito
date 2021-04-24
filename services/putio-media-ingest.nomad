
job "putio-media-ingest" {
  datacenters = ["casa"]
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
{{ with secret "kv/nidito/config/services/putio" }}
token = {"access_token":"{{ .Data.token }}","expiry":"0001-01-01T00:00:00Z"}
{{ end }}
EOF
        destination = "local/rclone.conf"
      }

      config {
        image = "registry.nidi.to/putio-media-ingest:202104220414"

        volumes = [
          "local/rclone.conf:/config/rclone/rclone.conf",
          "/volume1/media/dropbox/:/media",
        ]
      }

      resources {
        cpu = 40
        memory = 800
      }
    }
  }

}
