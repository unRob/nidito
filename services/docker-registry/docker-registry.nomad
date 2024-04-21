variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "docker-registry" {
  datacenters = ["casa"]
  type        = "service"
  namespace   = "infra-runtime"

  group "registry" {
    count = 1
    update {
      max_parallel = 1
    }

    restart {
      # on failure, restart at most
      attempts = 20
      # during
      interval = "20m"
      # waiting after a crash
      delay = "5s"
      # after which, continue waiting `interval` units
      # before retrying
      mode = "delay"
    }

    network {
      port "http" {
        host_network = "private"
      }
      port "metrics" {
        host_network = "private"
      }
      port "auth" {
        host_network = "private"
      }
    }

    task "auth" {
      vault {
        role = "docker-registry"
        change_mode = "signal"
        change_signal = "SIGHUP"
      }
      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      driver = "docker"

      resources {
        cpu        = 128
        memory     = 64
        memory_max = 512
      }

      config {
        image = "${var.package.auth.image}:${var.package.auth.version}"
        args = [
          "--alsologtostderr",
          "${NOMAD_SECRETS_DIR}/auth.yaml"
        ]
        ports = ["auth"]
      }

      template {
        destination = "secrets/auth.key"
        data        = <<-PEM
        {{- $zone := env "meta.dns_zone" -}}
        {{- with secret (printf "cfg/svc/tree/%s:docker-registry" $zone) -}}
        {{ .Data.auth.key }}
        {{ end }}
        PEM
      }

      template {
        destination = "${NOMAD_ALLOC_DIR}/auth.pem"
        data        = <<-PEM
        {{- $zone := env "meta.dns_zone" -}}
        {{- with secret (printf "cfg/svc/tree/%s:docker-registry" $zone) -}}
        {{ .Data.auth.certificate }}
        {{ end }}
        PEM
      }

      template {
        data        = file("auth.yaml")
        destination = "secrets/auth.yaml"
      }

      service {
        name = "registry-auth"
        port = "auth"
        tags = [
          "nidito.infra",
        ]

        meta {
          nidito-acl = "allow altepetl"
        }

        check {
          type     = "tcp"
          interval = "60s"
          timeout  = "5s"
        }
      }
    }

    task "registry" {
      vault {
        role = "docker-registry"
        change_mode = "signal"
        change_signal = "SIGHUP"
      }
      constraint {
        attribute = "${meta.storage}"
        operator  = "set_contains_any"
        value     = "primary,secondary"
      }

      driver = "docker"

      template {
        destination = "local/config.yml"
        data        = file("registry.yaml")
      }

      config {
        image = "${var.package.registry.image}:${trimprefix(var.package.registry.version, "v")}"

        ports = ["http", "metrics"]

        volumes = [
          "local/config.yml:/etc/docker/registry/config.yml",
        ]
      }

      resources {
        cpu    = 100
        memory = 128
        memory_max = 512
      }

      service {
        name = "registry-metrics"
        port = "metrics"

        tags = [
          "nidito.infra",
          "nidito.metrics.enabled",
        ]

        check {
          name     = "alive"
          type     = "tcp"
          interval = "60s"
          timeout  = "5s"
        }
      }

      service {
        name = "registry"
        port = "http"
        tags = [
          "nidito.infra",
          "nidito.dns.enabled",
          "nidito.http.enabled",
        ]

        meta {
          nidito-acl                 = "allow altepetl; allow qro0"
          nidito-http-max-body-size  = "700m"
          nidito-http-location-proxy = "/auth registry-auth ${NOMAD_PORT_auth}"
        }

        check {
          type     = "tcp"
          interval = "60s"
          timeout  = "5s"
        }
      }
    }
  }
}
