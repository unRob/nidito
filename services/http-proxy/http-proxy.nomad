variable "package" {
  type = map(object({
    image   = string
    version = string
  }))
  default = {}
}

locals {
  resources = {
    cpu    = 100
    memory = 128
  }

  ports = {
    http  = 80
    https = 443
  }
}

job "http-proxy" {
  datacenters = ["casa", "qro0"]
  type        = "system"
  priority    = 80

  vault {
    policies = ["http-proxy"]

    change_mode   = "restart"
    change_signal = "SIGHUP"
  }

  update {
    max_parallel = 2
    stagger      = "10s"
  }

  group "http-proxy" {
    restart {
      # on failure, restart at most
      attempts = 4
      # during
      interval = "1m"
      # waiting after a crash
      delay = "15s"
      # after which, continue waiting `interval` units
      # before retrying
      mode = "delay"
    }

    network {
      port "http" {
        static       = local.ports.http
        host_network = "private"
      }

      port "https" {
        static       = local.ports.https
        host_network = "private"
      }
    }

    task "nginx" {
      constraint {
        attribute = "${meta.os_family}"
        operator  = "!="
        value     = "macos"
      }

      driver = "docker"

      template {
        destination = "local/nidito/proxied-services"
        data        = file("proxied-services.json.tpl")
        change_mode = "noop"
      }

      template {
        destination   = "local/conf.d/default.conf"
        data          = file("nginx.conf")
        change_mode   = "signal"
        change_signal = "SIGHUP"
        splay         = "10s"
      }

      template {
        destination = "local/docker-entrypoint.d/05-get-ssl-certs.sh"
        data        = "#!/bin/sh /secrets/ssl/write-ssl"
        perms       = 0777
        change_mode = "restart"
      }

      template {
        destination = "local/on-ssl-change"
        data        = <<-SH
          #!/usr/bin/env sh
          /secrets/ssl/write-ssl
          nginx -s reload
        SH
        perms       = 0777
        change_mode = "restart"
        splay       = "10s"
      }

      template {
        destination = "secrets/ssl/write-ssl"
        data        = file("docker-entrypoint.d/05-get-ssl-certs.sh")
        perms       = 0777
        change_mode = "script"
        change_script {
          command       = "${NOMAD_TASK_DIR}/on-ssl-change"
          timeout       = "10s"
          fail_on_error = false
        }
        splay = "10s"
      }

      config {
        image        = "nginx:stable-alpine"
        network_mode = "host"

        ports = ["http", "https"]

        volumes = [
          "secrets/ssl:/ssl",
          "local/conf.d:/etc/nginx/conf.d",
          "local/docker-entrypoint.d/05-get-ssl-certs.sh:/docker-entrypoint.d/05-get-ssl-certs.sh",
          "local/nidito:/var/lib/www/nidito",
          "/nidito/http-proxy:/nidito"
        ]
      }

      resources {
        cpu    = local.resources.cpu
        memory = local.resources.memory
      }

      service {
        name         = "nginx"
        port         = "http"
        address_mode = "host"

        tags = [
          "nidito.infra",
          "nidito.dns.enabled",
          "nidito.ingress.enabled",
        ]

        meta {
          nidito-acl = "allow external"
        }

        check {
          type     = "http"
          port     = "http"
          path     = "/status"
          interval = "60s"
          timeout  = "2s"
        }
      }
    }
  }

  group "http-proxy-macos" {
    restart {
      # on failure, restart at most
      attempts = 100
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
        static       = local.ports.http
        host_network = "private"
      }

      port "https" {
        static       = local.ports.https
        host_network = "private"
      }
    }

    task "nginx-macos" {
      constraint {
        attribute = "${meta.os_family}"
        value     = "macos"
      }

      driver = "raw_exec"

      template {
        destination = "local/nidito/proxied-services"
        data        = file("proxied-services.json.tpl")
        change_mode = "noop"
      }

      template {
        destination = "local/conf.d/default.conf"
        data = replace(
          replace(
            replace(
              file("nginx.conf"),
              "/ssl",
              "{{env \"NOMAD_SECRETS_DIR\" }}/ssl"
            ),
            "/var/lib/www",
            "{{ env \"NOMAD_TASK_DIR\" }}/nidito"
          ),
          "resolver 127.0.0.11",
          "resolver 10.42.20.1"
        )
        change_mode   = "signal"
        change_signal = "SIGHUP"
        splay         = "10s"
      }

      template {
        destination   = "local/nginx.conf"
        data          = file("macos/nginx.conf")
        change_mode   = "signal"
        change_signal = "SIGHUP"
        splay         = "10s"
      }

      template {
        destination   = "local/mime.types"
        data          = file("macos/mime.types")
        change_mode   = "signal"
        change_signal = "SIGHUP"
        splay         = "10s"
      }

      template {
        destination = "local/on-ssl-change"
        data        = <<-SH
          #!/usr/bin/env bash
          "${NOMAD_SECRETS_DIR}/secrets/ssl/write-ssl
          # for some reason this returns exit code 129 and this makes nomad restart the whole thing
          /usr/local/bin/nginx -c  {{ env "NOMAD_TASK_DIR" }}/nginx.conf -s reload || true
        SH
        perms       = 0777
        change_mode = "restart"
        splay       = "10s"
      }

      template {
        destination = "secrets/ssl/write-ssl"
        data        = replace(file("docker-entrypoint.d/05-get-ssl-certs.sh"), "/ssl", "${NOMAD_SECRETS_DIR}/ssl")
        perms       = 0777
        change_mode = "script"
        change_script {
          command       = "${NOMAD_TASK_DIR}/on-ssl-change"
          timeout       = "10s"
          fail_on_error = false
        }
        splay = "10s"
      }


      template {
        destination = "local/entrypoint.sh"
        data        = <<-SH
          #!/usr/bin/env bash
          set -o errexit
          ${NOMAD_SECRETS_DIR}/ssl/write-ssl
          exec /usr/local/bin/nginx -c {{ env "NOMAD_TASK_DIR" }}/nginx.conf
        SH
        perms       = 0777
      }


      config {
        command = "/local/entrypoint.sh"
      }

      resources {
        cpu    = local.resources.cpu
        memory = local.resources.memory
      }

      service {
        name = "nginx"
        port = "http"

        tags = [
          "nidito.infra",
          "nidito.dns.enabled",
          "nidito.ingress.enabled",
        ]

        meta {
          nidito-acl = "allow external"
        }

        check {
          type     = "http"
          port     = "http"
          path     = "/status"
          interval = "60s"
          timeout  = "2s"
        }
      }
    }
  }
}
