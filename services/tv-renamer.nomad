job "tv-renamer" {
  datacenters = ["brooklyn"]
  type = "batch"

  group "tv-renamer" {

    task "tv-renamer" {
      driver = "docker"

      constraint {
        attribute = "${meta.nidito-storage}"
        value     = "primary"
      }

      config {
        image = "registry.nidi.to/tv-renamer:latest"

        volumes = [
          "/volume1/media/:/media",
        ]
      }

      resources {
        cpu = 100
        memory = 300
        network {
          mbits = 10
        }
      }
    }
  }

}
