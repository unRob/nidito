
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

      // workload identity is broken for periodic tasks
      // https://github.com/hashicorp/nomad/pull/17018
      // identity {
      //   env = true
      //   file = false
      // }

      template {
        destination = "secrets/env"
        env = true
        data = <<ENV
          TARGET="/media"
          NOMAD_TOKEN="{{ with secret "nomad/creds/service-putio" }}{{ .Data.secret_id }}{{ end }}"
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

      config {
        image = "registry.nidi.to/putio-media-ingest:202304290501"

        volumes = [
          "local/sync.sh:/sync.sh",
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
