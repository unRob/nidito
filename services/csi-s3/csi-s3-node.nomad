variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "csi-s3-node" {
  datacenters = ["casa"]
  type = "system"


  group "csi-s3-node" {
    task "node" {
      driver = "docker"

      resources {
        cpu = 100
        memory = 512
        memory_max = 1024
      }

      config {
        image = "${var.package.self.image}:${var.package.self.version}"

        args = [
          "--endpoint=unix:///csi/csi.sock",
          "--nodeid=${node.unique.name}",
          "--logtostderr",
          "--v=5",
        ]

        privileged = true
      }

      csi_plugin {
        id        = "csi-s3"
        type      = "node"
        mount_dir = "/csi"
      }
    }
  }
}
