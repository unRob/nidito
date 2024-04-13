variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "ssl" {
  datacenters = ["casa", "qro0"]
  type        = "batch"

  periodic {
    crons            = [
      "@weekly"
    ]

    prohibit_overlap = true
  }

  group "ssl" {

    task "ssl" {
      driver = "docker"
      vault {
        role        = "ssl"
        change_mode = "restart"
      }

      template {
        destination = "secrets/env"
        data        = <<-ENV
          VAULT_ADDR={{ env "VAULT_ADDR" }}
          CONSUL_HTTP_ADDR={{ env "CONSUL_HTTP_ADDR" }}
          {{ with secret "consul-acl/creds/service-ssl" -}}
          CONSUL_HTTP_TOKEN={{ .Data.token }}
          {{- end }}
        ENV
        env         = true
      }

      config {
        image   = "${var.package.self.image}:${var.package.self.version}"
        command = "${node.region}"
      }

      resources {
        cpu        = 100
        memory     = 100
        memory_max = 500
      }
    }
  }
}
