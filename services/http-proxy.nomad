job "http-proxy" {
  datacenters = ["brooklyn"]
  type = "system"
  priority = 80

  vault {
    policies = ["http-proxy"]

    change_mode   = "signal"
    change_signal = "SIGHUP"
  }

  group "http-proxy" {
    restart {
      # on failure, restart at most
      attempts = 10
      # during
      interval = "5m"
      # waiting after a crash
      delay = "25s"
      # after which, continue waiting `interval` units
      # before retrying
      mode = "delay"
    }


    task "nginx" {
      constraint {
        attribute = "${meta.arch}"
        operator  = "!="
        value     = "Darwin"
      }

      driver = "docker"

      template {
        destination = "secrets/ssl/star.nidi.to.crt"
        data = <<PEM
{{- with secret "kv/nidito/letsencrypt/cert/nidi.to" }}
{{ .Data.cert }}
{{- end }}
PEM
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        destination = "secrets/ssl/star.nidi.to.key"
        data = <<PEM
{{- with secret "kv/nidito/letsencrypt/cert/nidi.to" }}
{{ .Data.private_key }}
{{- end }}
PEM
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        destination = "local/default.conf"
        data = <<NGINX
server {
  listen       80 default_server;
  listen  [::]:80;
  server_name  localhost;

  location /status {
    allow 127.0.0.1;
    allow 10.10.0.0/28;
    deny all;
    stub_status;
  }
}

{{- $nodeName := env "node.unique.name"}}
{{- range services }}
{{- if in .Tags "nidito.http.enabled" }}
{{- range service .Name }}
{{- if eq $nodeName .Node }}
{{- $zoneName := index .ServiceMeta "nidito-http-zone" }}
server {
  listen 80;
  server_name {{ .Name }} {{ .Name }}.nidi.to;
  return 301 https://{{ .Name }}.nidi.to;
}

server {
  listen 443 ssl http2;
  server_name {{ .Name }}.nidi.to;

  allow 127.0.0.1;
  # Zone: {{ $zoneName }}
  {{- with secret (printf "kv/nidito/config/http/zones/%s" $zoneName) }}
  {{- $networkNames := .Data.json | parseJSON }}
  {{- range $networkNames }}
  {{- $network := . }}
  {{- with secret "kv/nidito/config/networks" }}
  allow {{ index .Data $network }};
  {{- end }}
  {{- end }}
  {{- end }}
  deny all;

  ssl_certificate     /ssl/star.nidi.to.crt;
  ssl_certificate_key /ssl/star.nidi.to.key;
  ssl_protocols       TLSv1.2;
  ssl_prefer_server_ciphers on;
  ssl_ciphers "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384";
  {{- /*The most CPU-intensive operation is the SSL handshake. There are two ways to minimize the number of these operations per client: the first is by enabling keepalive connections to send several requests via one connection */}}
  keepalive_timeout   70;

  location / {
    add_header X-Edge {{ $nodeName }} always;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    proxy_pass http://{{ .Name }}.service.consul:{{ .Port }};
  }
}


{{- end }}
{{- end }}
{{- end }}
{{- end }}
NGINX
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      config {
        image = "nginx:stable-alpine"
        network_mode = "host"

        port_map {
          http = 80
          https = 443
        }

        labels {
          "co.elastic.logs/module" = "nginx"
        }

        volumes = [
          "secrets/ssl:/ssl",
          "local/default.conf:/etc/nginx/conf.d/default.conf",
        ]
      }

      resources {
        cpu    = 100
        memory = 128
        network {
          mbits = 10
          port "http" {
            static = 80
          }
          port "https" {
            static = 443
          }
        }
      }

      service {
        name = "nginx"
        port = "http"

        tags = [
          "nidito.infra",
          "nidito.dns.enabled",
        ]

        check {
          type     = "http"
          path     = "/status"
          interval = "60s"
          timeout  = "2s"
        }
      }

    }
  }
}
