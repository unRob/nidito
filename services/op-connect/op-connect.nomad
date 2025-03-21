variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

job "op-connect" {
  datacenters = ["casa", "qro0"]
  type        = "system"
  priority    = 90
  namespace   = "infra-runtime"

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
      vault {
        role = "op"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      lifecycle {
        hook = "prestart"
        sidecar = false
      }

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
        image = "${var.package.api.image}-sync:${var.package.api.version}"
        ports = ["sync"]
      }
    }

    task "api" {
      driver = "docker"
      vault {
        role = "op"
        change_mode   = "signal"
        change_signal = "SIGHUP"
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
        image = "${var.package.api.image}-api:${var.package.api.version}"
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
