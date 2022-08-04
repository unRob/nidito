job "http-proxy" {
  datacenters = ["casa", "nyc1"]
  type = "system"
  priority = 80

  vault {
    policies = ["http-proxy"]

    change_mode   = "restart"
    change_signal = "SIGHUP"
  }

  update {
    max_parallel = 1
    min_healthy_time = "10s"
    healthy_deadline = "3m"
    progress_deadline = "5m"
    auto_revert = true
  }

  group "http-proxy" {
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
        static = 80
      }
      port "https" {
        static = 443
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
        data = file("proxied-services.json.tpl")
        change_mode   = "noop"
      }

      template {
        destination = "local/conf.d/default.conf"
        data = file("nginx.conf")
        change_mode   = "signal"
        change_signal = "SIGHUP"
        splay = "10s"
      }

      template {
        destination = "local/docker-entrypoint.d/05-get-ssl-certs.sh"
        perms = 0777
        data = "#!/bin/sh /secrets/ssl/write-ssl"
      }

      template {
        destination = "secrets/ssl/write-ssl"
        perms = 0777
        change_mode   = "restart"
        data = file("docker-entrypoint.d/05-get-ssl-certs.sh")
        change_signal = "SIGHUP"
        splay = "10s"
      }

      config {
        image = "nginx:stable-alpine"
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
        cpu    = 100
        memory = 128
      }

      service {
        name = "nginx"
        port = "http"
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
}
