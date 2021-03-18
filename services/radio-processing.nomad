
job "process-recordings" {
  datacenters = ["casa"]
  type = "batch"

  parameterized {

  }

  group "icecast" {
    task "process-recordings" {

      constraint {
        attribute = "${meta.nidito-storage}"
        value     = "primary"
      }

      driver = "docker"

      template {
        destination = "local/database-init.sql"
        perms = 750
        data = file("radio-processing/database.sql")
      }

      template {
        destination = "local/entrypoint.sh"
        perms = 750
        data = file("radio-processing/entrypoint.sh")
      }

      template {
        destination = "secrets/file.env"
        env = true
        data = "SOURCE=/recordings"
      }

      config {
        image = "registry.nidi.to/radio-processing:202103180413"
        command = "./local/entrypoint.sh"

        volumes = [
          "local/entrypoint.sh:/entrypoint.sh",
          "/volume1/nidito/cajon/ruiditos:/recordings"
        ]
      }

      resources {
        cpu = 1000
        memory = 800
      }

    }
  }
}
