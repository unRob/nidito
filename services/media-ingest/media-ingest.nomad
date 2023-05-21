
job "media-ingest" {
  datacenters = ["casa"]
  type = "batch"
  priority = 10

  periodic {
    cron             = "*/15 * * * * *"
    prohibit_overlap = true
  }

  vault {
    policies = ["media-ingest"]
    change_mode = "restart"
  }

  group "media-ingest" {

    task "rclone" {
      driver = "docker"

      constraint {
        attribute = "${meta.storage}"
        value     = "primary"
      }

      // // workload identity is broken for periodic tasks
      // // https://github.com/hashicorp/nomad/pull/17018
      // identity {
      //   env = true
      //   file = false
      // }

      template {
        destination = "secrets/env"
        env = true
        data = <<ENV
          TARGET="/media"
          NOMAD_TOKEN="{{ with secret "nomad/creds/service-media-ingest" }}{{ .Data.secret_id }}{{ end }}"
        ENV
      }

      template {
        destination = "local/rclone.conf"
        data = <<-EOF
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
        cpu = 40
        memory = 100
        memory_max = 800
      }
    }
  }

}