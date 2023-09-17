/*
Bridge between 1Password public's API and our local network

docs: https://developer.1password.com/docs/connect
code: https://github.com/1Password/connect
*/

locals {
  version = "1.7"
}

job "op-connect" {
  datacenters = ["nyc1", "casa"]
  type        = "system"
  priority    = 90

  constraint {
    attribute = "${meta.storage}"
    operator  = "set_contains_any"
    value     = "primary,secondary"
  }

  update {
    max_parallel = 1
    stagger      = "10s"
  }

  group "op-connect" {

    vault {
      policies = ["op"]

      change_mode   = "signal"
      change_signal = "SIGHUP"
    }

    network {
      port "http" {
        static       = 5577
        to           = 8443
        host_network = "private"
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

      resources {
        cpu        = 100
        memory     = 200
        memory_max = 500
      }

      env {
        OP_BUS_PORT      = "${NOMAD_PORT_sync}"
        OP_BUS_PEERS     = "${NOMAD_ADDR_api}"
        XDG_DATA_HOME    = "${NOMAD_ALLOC_DIR}"
        OP_SESSION       = "${NOMAD_SECRETS_DIR}/1password-credentials.json"
        OP_TLS_KEY_FILE  = "${NOMAD_SECRETS_DIR}/tls.key"
        OP_TLS_CERT_FILE = "${NOMAD_SECRETS_DIR}/tls.pem"
      }

      template {
        destination = "secrets/tls.key"
        data        = "{{ with secret (printf \"nidito/service/op/%s\" (env \"node.unique.name\") ) }}{{ .Data.key }}{{ end }}"
      }

      template {
        destination = "secrets/tls.pem"
        data        = "{{ with secret (printf \"nidito/service/op/%s\" (env \"node.unique.name\") ) }}{{ .Data.cert }}{{ end }}"
      }

      template {
        destination = "secrets/1password-credentials.json"
        data        = "{{ with secret \"nidito/service/op/_credentials\" }}{{ .Data.json }}{{ end }}"
      }

      config {
        image = "1password/connect-sync:${version}"
        ports = ["sync"]
      }
    }

    task "api" {
      driver = "docker"

      lifecycle {
        hook    = "prestart"
        sidecar = true
      }

      resources {
        cpu        = 100
        memory     = 200
        memory_max = 500
      }

      env {
        OP_BUS_PORT      = "${NOMAD_PORT_api}"
        OP_BUS_PEERS     = "${NOMAD_ADDR_sync}"
        XDG_DATA_HOME    = "${NOMAD_ALLOC_DIR}"
        OP_SESSION       = "${NOMAD_SECRETS_DIR}/1password-credentials.json"
        OP_TLS_KEY_FILE  = "${NOMAD_SECRETS_DIR}/tls.key"
        OP_TLS_CERT_FILE = "${NOMAD_SECRETS_DIR}/tls.pem"
      }

      template {
        destination = "secrets/tls.key"
        data        = "{{ with secret (printf \"nidito/service/op/%s\" (env \"node.unique.name\") ) }}{{ .Data.key }}{{ end }}"
      }

      template {
        destination = "secrets/tls.pem"
        data        = "{{ with secret (printf \"nidito/service/op/%s\" (env \"node.unique.name\") ) }}{{ .Data.cert }}{{ end }}"
      }

      template {
        destination = "secrets/1password-credentials.json"
        data        = "{{ with secret \"nidito/service/op/_credentials\" }}{{ .Data.json }}{{ end }}"
      }

      config {
        image = "1password/connect-api:${version}"
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
          "nidito.dns.enabled",
          "nidito.metrics.enabled"
        ]

        meta {
          nidito-acl                = "allow external"
          nidito-http-max-body-size = "50m"
          nidito-http-backend-proxy = "https://op.query.consul"
          nidito-metrics-scheme     = "https"
        }
      }
    }

  }
}
