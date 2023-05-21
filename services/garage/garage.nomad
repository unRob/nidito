job "garage" {
  datacenters = ["casa"]
  region = "casa"
  priority = 70

  constraint {
    attribute = "${meta.storage}"
    operator = "set_contains_any"
    value = "primary,secondary"
  }

  constraint {
    operator = "distinct_hosts"
    value    = "true"
  }


  vault {
    policies = ["garage"]

    change_mode   = "signal"
    change_signal = "SIGHUP"
  }

  group "garage" {
    count = 3

    update {
      max_parallel = 1
    }

     reschedule {
      delay          = "5s"
      delay_function = "fibonacci"
      max_delay      = "1h"
      unlimited      = true
    }

    restart {
      delay = "5s"
      // # delay_function = "fibonacci"
      # max_delay = "1h"
      # unlimited = true
      attempts = 20
      interval = "1h"
      mode = "delay"
    }


    network {
      port "rpc" {
        host_network = "private"
        to = 6600
        static = 6600
      }
      port "api" {
        host_network = "private"
      }
      port "s3" {
        host_network = "private"
      }
      port "web" {
        host_network = "private"
      }
    }


    task "garage" {
      driver = "docker"

      template {
        destination = "secrets/garage.toml"
        data = file("./garage.toml")
      }

      template {
        destination = "secrets/tls/ca.pem"
        data = <<-PEM
        {{- with secret "cfg/infra/tree/service:ca" }}
        {{ .Data.cert }}
        {{- end }}
        PEM
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      config {
        // image = "dxflrs/garage:v0.8.2"
        // building from https://git.deuxfleurs.fr/Deuxfleurs/garage/pulls/567
        image = "registry.nidi.to/garage-testing:202305210230"
        command = "/garage"
        args = ["--config", "${NOMAD_SECRETS_DIR}/garage.toml", "server"]
        ports = ["rpc", "s3", "web", "api"]
        hostname = "${node.unique.name}"

        volumes = [
          "/nidito/garage/data:/storage/data",
          "/nidito/garage/metadata:/storage/metadata",
        ]
      }

      resources {
        cpu = 50
        memory = 512
        memory_max = 1024
      }

      service {
        name = "garage-api"
        port = "api"

        check {
          type     = "http"
          path     = "/health"
          interval = "60s"
          timeout  = "2s"
        }

        tags = [
          "nidito.dns.enabled",
          "nidito.http.enabled",
          "nidito.metrics.enabled",
        ]

        meta {
          nidito-acl = "allow altepetl"
          nidito-http-buffering = "off"
          nidito-dns-alias = "api.garage"
          nidito-http-tls = "garage.nidi.to"
        }
      }

      service {
        name = "garage-s3"
        port = "s3"

        tags = [
          "nidito.dns.enabled",
          "nidito.http.enabled",
          "nidito.http.public",
        ]

        meta {
          nidito-acl = "allow external"
          nidito-http-buffering = "off"
          // needs to allow file uploads
          nidito-http-max-body-size = "2048m"
          nidito-dns-alias = "s3.garage; *.s3.garage"
          nidito-http-tls = "garage.nidi.to"
        }
      }

      service {
        name = "garage-web"
        port = "web"

        tags = [
          "nidito.dns.enabled",
          "nidito.http.enabled",
          "nidito.http.public",
        ]

        meta {
          nidito-acl = "allow external"
          nidito-http-buffering = "off"
          nidito-http-domain = "web.garage"
          nidito-dns-alias = "web.garage; *.web.garage"
          nidito-http-tls = "garage.nidi.to"
        }
      }

    }
  }
}
