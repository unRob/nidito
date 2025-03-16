variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "postgres" {
  datacenters = ["casa"]
  priority = 80
  namespace = "infra-runtime"

  group "postgres" {
    count = 2
    restart {
      delay = "15s"
      attempts = 40
      interval = "10m"
      mode = "delay"
    }

    network {
      port "api" {
        static = 5433
        host_network = "private"
      }
      port "pg" {
        # Synology DSM is already using the default port, so fuck me.
        static = 5434
        host_network = "private"
      }
    }

    task "postgres" {
      driver = "docker"
      user   = 999

      vault {
        role = "postgres"
      }

      constraint {
        attribute = "${meta.storage}"
        operator  = "set_contains_any"
        value     = "primary,secondary"
      }

      constraint {
        # docker on macos strikes again. could not get past
        # file permission errors in macos
        attribute = "${meta.os_family}"
        operator  = "!="
        value     = "macos"
      }

      resources {
        cpu = 1000
        memory = 1024
        memory_max = 4092
      }

      config {
        image = "${var.package.self.image}:${var.package.self.version}"
        ports = ["api", "pg"]
        network_mode = "host"
        args = [
          "/secrets/patroni.yaml"
        ]

        volumes = [
          "/nidito/postgres:/pg-data"
        ]

      }

      template {
        destination   = "secrets/patroni.yaml"
        data          = file("./patroni.yaml")
        change_mode   = "restart"
      }

      template {
        destination   = "secrets/tls/ca.pem"
        data= "{{ with secret \"cfg/infra/tree/service:ca\" }}{{ .Data.cert }}{{ end }}"
        change_mode   = "restart"
        perms = 0744
        uid = 999
      }


      template {
        destination = "secrets/tls/key.pem"
        data = "{{ with secret \"cfg/svc/tree/nidi.to:postgres\" }}{{ .Data.tls.key }}{{ end }}"
        change_mode   = "restart"
        perms = 0600
        uid = 999
      }

      template {
        destination = "secrets/tls/cert.pem"
        data = "{{ with secret \"cfg/svc/tree/nidi.to:postgres\" }}{{ .Data.tls.cert }}{{ end }}"
        change_mode   = "signal"
        change_signal = "SIGHUP"
        perms = 0600
        uid = 999
      }

      service {
        name = "patroni"
        port = "api"

        check {
          type     = "http"
          protocol = "https"
          # https://patroni.readthedocs.io/en/latest/rest_api.html#health-check-endpoints
          path     = "/liveness"
          interval = "60s"
          timeout  = "5s"
        }

        tags = [
          "nidito.dns.enabled",
          "nidito.http.enabled",
          "nidito.metrics.enabled",
        ]

        meta {
          nidito-acl = "allow altepetl"
          nidito-metrics-scheme = "https"
        }
      }
    }
  }
}
