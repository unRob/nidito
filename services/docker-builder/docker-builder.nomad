variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "docker-builder" {
  datacenters = ["casa"]
  type        = "system"
  namespace   = "infra-runtime"

  constraint {
    attribute = "${meta.builder}"
    operator  = "=="
    value     = "enabled"
  }

  group "docker-builder" {
    restart {
      delay    = "15s"
      attempts = 40
      interval = "10m"
      mode     = "delay"
    }

    network {
      port "socket" {
        static = 5580
        to = 5580
      }
    }

    task "docker-builder" {
      driver = "docker"

      vault {
        role          = "docker-builder"
      }

      // template {
      //   destination = "secrets/key.pem"
      //   data        = "{{ with secret (printf \"nidito/tls/%s\" (env \"meta.dns_zone\") ) }}{{ .Data.private_key }}{{ end }}"
      // }

      // template {
      //   destination = "secrets/cert.pem"
      //   data        = "{{ with secret (printf \"nidito/tls/%s\" (env \"meta.dns_zone\") ) }}{{ .Data.cert }}{{ end }}"
      // }

      resources {
        cpu        = 500
        memory     = 1024
        memory_max = 2048
      }

      config {
        image = "${var.package.self.image}:${var.package.self.version}"
        ports = ["socket"]
        privileged = true
        args = [
          "--addr", "tcp://0.0.0.0:5580",
          "--allow-insecure-entitlement", "network.host"
        ]

        // created on each node with
        // docker volume create buildkit_state
        mount {
          type = "volume"
          source = "buildkit_state"
          target = "/var/lib/buildkit"
          readonly = false
        }
      }

      service {
        name = "buildx"
        port = "socket"

        check {
          type     = "tcp"
          interval = "60s"
          timeout  = "10s"
        }

        tags = []

        meta {
          nidito-acl = "allow altepetl"
        }
      }
    }
  }
}
