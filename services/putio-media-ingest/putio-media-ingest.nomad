
job "putio-media-ingest" {
  datacenters = ["casa"]
  type = "batch"
  priority = 10

  periodic {
    cron             = "*/15 * * * * *"
    prohibit_overlap = true
  }

   vault {
    policies = ["putio-media-ingest"]
    change_mode = "restart"
  }

  group "putio-media-ingest" {

    task "rclone" {
      driver = "docker"

      constraint {
        attribute = "${meta.storage}"
        value     = "primary"
      }

      identity {
        env = true
      }

      env {
        TARGET = "/media"
      }

      template {
        data = <<EOF
[putio]
type = putio
{{ with secret "cfg/infra/tree/provider:putio" }}
token = {"access_token":"{{ .Data.token }}","expiry":"0001-01-01T00:00:00Z"}
{{ end }}
EOF
        destination = "local/rclone.conf"
      }

      config {
        image = "registry.nidi.to/putio-media-ingest:202304132335"


        volumes = [
          "local/rclone.conf:/config/rclone/rclone.conf",
          "/volume1/media/dropbox/:/media",
        ]
      }

      resources {
        cpu = 40
        memory = 100
        memory_max = 800
      }
    }
  }

}
