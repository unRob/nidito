variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "media-ingest" {
  datacenters = ["casa"]
  type        = "batch"
  priority    = 10

  parameterized {}

  vault {
    policies    = ["media-ingest"]
    change_mode = "restart"
  }

  group "media-ingest" {

    task "rclone" {
      driver = "docker"

      constraint {
        attribute = "${meta.storage}"
        value     = "primary"
      }

      identity {
        env = true
      }

      template {
        destination = "secrets/env"
        env         = true
        data        = <<ENV
          TARGET="/media"
        ENV
      }

      template {
        destination = "local/rclone.conf"
        data        = <<-EOF
          [putio]
          type = putio
          {{ with secret "cfg/infra/tree/provider:putio" }}
          token = {"access_token":"{{ .Data.token }}","expiry":"0001-01-01T00:00:00Z"}
          {{ end }}
        EOF
      }

      // template {
      //   destination = "local/sync.sh"
      //   data = file("./sync.sh")
      //   perms = 0777
      // }

      config {
        image = "registry.nidi.to/media-ingest:202305212142"
        // command = "${NOMAD_TASK_DIR}/sync.sh"

        volumes = [
          "local/rclone.conf:/config/rclone/rclone.conf",
          "/volume1/media/dropbox/:/media",
        ]
      }

      resources {
        cpu        = 40
        memory     = 100
        memory_max = 800
      }
    }
  }

}
