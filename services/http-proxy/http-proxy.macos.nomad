job "http-proxy-macos" {
  datacenters = ["brooklyn"]
  type = "system"
  priority = 80

  vault {
    policies = ["http-proxy"]

    change_mode   = "signal"
    change_signal = "SIGHUP"
  }

  group "http-proxy-macos" {
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


    task "nginx-macos" {
      constraint {
        // Docker for mac is so broken on macos...
        // https://github.com/docker/for-mac/issues/2716
        attribute = "${meta.arch}"
        value     = "Darwin"
      }

      driver = "raw_exec"

      template {
        destination = "local/ssl/star.nidi.to.crt"
        data = <<PEM
{{- with secret "kv/nidito/letsencrypt/cert/nidi.to" }}
{{ .Data.cert }}
{{- end }}
PEM
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        destination = "local/ssl/star.nidi.to.key"
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
{{- with secret "kv/nidito/config/dns" }}
{{- scratch.Set "zone" .Data.zone }}
{{- end }}
{{- $nodeName := env "node.unique.name"}}
{{ range services }}
{{- if in .Tags "nidito.http.enabled" }}
{{- range service .Name }}
{{- if or (eq $nodeName .Node) (in .Tags "nidito.http.public") }}
{{- $zoneName := or (index .ServiceMeta "nidito-http-zone") "trusted" }}

server {
  listen *:80;
  server_name {{ .Name }} {{ .Name }}.{{ scratch.Get "zone" }};
  return 301 https://{{ .Name }}.{{ scratch.Get "zone" }};
}

server {
  listen *:443 ssl http2;
  server_name {{ .Name }}.{{ scratch.Get "zone" }};

  allow 127.0.0.1;
  {{- with secret (printf "kv/nidito/config/http/zones/%s" $zoneName) }}
  # Zone: {{ $zoneName }}
  {{- $networkNames := .Data.json | parseJSON }}
  {{- range $networkNames }}
  {{- $network := . }}
  {{- with secret "kv/nidito/config/networks" }}
  allow {{ index .Data $network }};
  {{- end }}
  {{- end }}
  {{- end }}
  {{- if not (in .Tags "nidito.http.public") }}
  {{- scratch.MapSet "services" .Name "local" }}
  deny all;
  {{- else }}
  {{- scratch.MapSet "services" .Name "public" }}
  {{ end }}

  ssl_certificate     {{ env "NOMAD_TASK_DIR" }}/ssl/star.{{ scratch.Get "zone" }}.crt;
  ssl_certificate_key {{ env "NOMAD_TASK_DIR" }}/ssl/star.{{ scratch.Get "zone" }}.key;
  ssl_protocols       TLSv1.2;
  ssl_prefer_server_ciphers on;
  ssl_ciphers "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384";
  {{- /*The most CPU-intensive operation is the SSL handshake. There are two ways to minimize the number of these operations per client: the first is by enabling keepalive connections to send several requests via one connection */}}
  keepalive_timeout   70;

  location / {
    client_max_body_size 500m;

    add_header X-Edge {{ $nodeName }} always;
    add_header X-Nidito-Service {{ .Name }} always;

    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

    {{- if eq (index .ServiceMeta "nidito-http-buffering") "off" }}
    proxy_buffering "off";
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    {{- end }}

    resolver 10.10.0.1 valid=30s;
    proxy_pass http://{{ .Address }}:{{ .Port }};
  }
}

{{- end }}
{{- end }}
{{- end }}
{{- end }}

server {
  listen      *:80 default_server;
  server_name  localhost;

  location /status {
    allow 127.0.0.1;
    allow 10.10.0.0/28;
    deny all;
    stub_status;
    access_log off;
  }

  location /nidito/proxied-services {
    allow 127.0.0.1;
    allow 10.10.0.0/28;
    deny all;
    access_log off;
    default_type application/json;
    return 200 '{ "node": "{{ $nodeName }}", "services": {{ scratch.Get "services" | explodeMap | toJSON }} }';
  }

  location / {
    client_max_body_size 128k;
    default_type application/json;
    return 200 '{"token": "$request_id", "role": "admin"}';
  }
}

NGINX
        change_mode   = "signal"
        change_signal = "SIGHUP"
        splay = "30s"
      }

      config {
        command = "/usr/local/etc/nginx/nomad.sh"
        args = [
          "-c", "/usr/local/etc/nginx/nginx.conf"
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
        name = "nginx-macos"
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