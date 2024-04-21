variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "csi-s3" {
  datacenters = ["casa"]
  namespace   = "infra-runtime"

  group "csi-s3" {
    task "controller" {
      driver = "docker"

      config {
        image = "${var.package.self.image}:${var.package.self.version}"

        args = [
          "--endpoint=unix://csi/csi.sock",
          "--nodeid=${node.unique.name}",
          "--logtostderr",
          "--v=5",
        ]

        privileged = true
      }

      csi_plugin {
        id        = "csi-s3"
        type      = "controller"
        mount_dir = "/csi"
        stage_publish_base_dir = "/local/csi"
      }
      resources {
        cpu    = 100
        memory = 512
        memory_max = 1024
      }
    }
  }
}
