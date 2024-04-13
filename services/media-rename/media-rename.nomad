variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "media-rename" {
  datacenters = ["casa"]
  type        = "batch"

  parameterized {}

  group "media-rename" {

    task "media-rename" {
      driver = "docker"

      vault {
        role    = "media-rename"
        change_mode = "restart"
      }

      constraint {
        attribute = "${meta.storage}"
        value     = "primary"
      }

      template {
        destination = "local/.mnamer-v2.json"
        data        = file("./.mnamer-v2.json")
      }

      config {
        image = "registry.nidi.to/media-rename:202305212152"

        volumes = [
          "local/.mnamer-v2.json:/app/.mnamer-v2.json",
          "/volume1/media/:/media",
        ]
      }

      resources {
        cpu        = 100
        memory     = 300
        memory_max = 800
      }
    }
  }

}
