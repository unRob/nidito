job "putio-media-ingest" {
  datacenters = ["brooklyn"]
  type = "batch"

  // parameterized {
  //   payload = "required"
  // }

  group "putio-media-ingest" {

    task "rclone" {
      driver = "docker"

      constraint {
        attribute = "${meta.hardware}"
        operator  = "="
        value     = "[[ consulKey "/nidito/config/nodes/chapultepec/hardware" ]]"
      }

      env {
        TARGET = "/media"
      }

      template {
        data = <<EOF
[putio]
type = putio
token = {"access_token":"{{ key "/nidito/service/putio/token" }}","expiry":"0001-01-01T00:00:00Z"}
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
