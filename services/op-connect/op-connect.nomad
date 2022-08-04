job "op-connect" {
  datacenters = ["nyc1"]
  type = "system"

  group "op-connect" {
    network {
      port "http" {
        host_network = "public"
      }
      port "sync" {
        host_network = "private"
      }
      port "api" {
        host_network = "private"
      }
    }

    task "sync" {
      driver = "docker"

      template {
        destination = "secrets/1password-credentials.json"
        # this file was dropped into the vm manually
        data = file("/root/op-connect/1password-credentials.json")
        change_mode   = "restart"
      }

      env {
        OP_BUS_PORT = "${NOMAD_PORT_sync}"
        OP_BUS_PEERS = "${NOMAD_ADDR_api}"
        XDG_DATA_HOME = "${NOMAD_ALLOC_DIR}"
        OP_SESSION = "${NOMAD_SECRETS_DIR}/1password-credentials.json"
      }

      config {
        image = "1password/connect-sync:latest"
        ports = ["sync"]
      }
    }

    task "api" {
      driver = "docker"

      template {
        destination = "secrets/1password-credentials.json"
        data = file("/root/op-connect/1password-credentials.json")
        change_mode   = "restart"
      }

      env {
        OP_BUS_PORT = "${NOMAD_PORT_api}"
        OP_BUS_PEERS = "${NOMAD_ADDR_sync}"
        OP_HTTP_PORT = "${NOMAD_PORT_http}"
        XDG_DATA_HOME = "${NOMAD_ALLOC_DIR}"
        OP_SESSION = "${NOMAD_SECRETS_DIR}/1password-credentials.json"
      }

      config {
        image = "1password/connect-api:latest"
        ports = ["http", "api"]
      }

      service {
        name = "op"
        port = "http"

        tags = [
          "nidito.service",
          "nidito.http.enabled",
          "nidito.http.public",
          "nidito.ingress.enabled",
          "nidito.dns.external"
        ]

        meta {
          nidito-acl = "allow external"
          nidito-http-max-body-size = "50m"
        }
      }
    }

  }
}
