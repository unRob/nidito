job "radio-processing" {
  datacenters = ["casa"]
  type = "batch"

  parameterized {}

  group "radio-processing" {
    task "radio-processing" {

      constraint {
        attribute = "${meta.storage}"
        value     = "primary"
      }

      driver = "docker"

      vault {
        policies = ["radio-processing"]

        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        destination = "local/database-init.sql"
        perms = 750
        data = file("database.sql")
      }

      template {
        destination = "local/entrypoint.sh"
        perms = 750
        data = file("entrypoint.sh")
      }

      template {
        destination = "secrets/file.env"
        env = true
        data = <<EOF
        SOURCE=/recordings
        {{- with secret "cfg/infra/tree/service:cdn" }}
        MC_HOST_cdn="https://{{ .Data.key }}:{{ .Data.secret }}@{{ .Data.endpoint }}/"
        {{- end }}
        EOF
      }

      config {
        image = "registry.nidi.to/radio-processing:202201140554"
        command = "./local/entrypoint.sh"

        volumes = [
          "local/entrypoint.sh:/entrypoint.sh",
          "/volume1/nidito/cajon/ruiditos:/recordings"
        ]
      }

      resources {
        cpu = 1000
        memory = 1000
      }

    }
  }
}
