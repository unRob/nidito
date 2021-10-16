job "http-proxy" {
  datacenters = ["casa"]
  type = "system"
  priority = 80

  vault {
    policies = ["http-proxy"]

    change_mode   = "signal"
    change_signal = "SIGHUP"
  }

  update {
    max_parallel = 2
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
        destination = "secrets/ssl/star.crt"
        data = <<-PEM
        {{- $dc := env "node.region" }}
        {{- with secret (printf "nidito/config/datacenters/%s/dns" $dc) }}
        {{- with secret (printf "nidito/tls/%s" .Data.zone) }}
        {{ .Data.cert }}
        {{- end }}
        {{ end }}
        PEM
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        destination = "secrets/ssl/star.key"
        data = <<-PEM
        {{- $dc := env "node.region" }}
        {{- with secret (printf "nidito/config/datacenters/%s/dns" $dc) }}
        {{- with secret (printf "nidito/tls/%s" .Data.zone) }}
        {{ .Data.private_key }}
        {{- end }}
        {{ end }}
        PEM
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        destination = "local/nidito/proxied-services"
        data = <<-JSON
        {{- $nodeName := env "node.unique.name"}}
        {{- range services }}
          {{- if in .Tags "nidito.http.enabled" }}
            {{- range service .Name }}
              {{- if not (in .Tags "nidito.http.public") }}
                {{- scratch.MapSet "services" .Name "local" }}
              {{- else }}
                {{- scratch.MapSet "services" .Name "public" }}
              {{- end }}
            {{- end }}
          {{- end }}
        {{- end }}
        {{- range $name, $data := (key "dns/static-entries" | parseJSON) }}
          {{- scratch.MapSet "services" $name "static" }}
        {{- end }}
        {
          "node": "{{ $nodeName }}",
          "services": {{ scratch.Get "services" | explodeMap | toJSON }}
        }
        JSON
      }

      template {
        destination = "local/default.conf"
        data = <<-NGINX
          server_names_hash_bucket_size 64;

          {{- $dc := env "node.region" }}
          {{- with secret (printf "nidito/config/datacenters/%s/dns" $dc) }}
          {{- scratch.Set "zone" .Data.zone }}
          {{- end }}

          {{- scratch.Set "network-external" "0.0.0.0/0" }}
          {{- range secrets "nidito/config/networks/" }}
            {{- if not (in . "/") }}
              {{- $netName := . }}
              {{- with secret (printf "nidito/config/networks/%s" .) }}
                {{- if index .Data "core" }}
                {{- scratch.SetX "core-network-range" .Data.range }}
                {{- scratch.SetX "core-network-name" $netName }}
                {{- end }}
                {{- scratch.Set (printf "network-%s" $netName) .Data.range }}
              {{- end }}
            {{- end }}
          {{- end }}

          {{- $nodeName := env "node.unique.name"}}
          {{ range services }}
            {{- if in .Tags "nidito.http.enabled" }}
              {{- range service .Name }}
          server {
            listen *:80;
            server_name {{ .Name }} {{ .Name }}.{{ scratch.Get "zone" }};
            return 301 https://{{ .Name }}.{{ scratch.Get "zone" }};
          }

          server {
            listen *:443 ssl http2;
            server_name {{ .Name }}.{{ scratch.Get "zone" }};

            allow 127.0.0.1;
            # acl: {{ or (index .ServiceMeta "nidito-acl") "none" }}
            {{- /*
            Transforms stuff like 'allow net1,net2; deny badNet' into
            allow 192.168.1.0/24;
            allow 192.168.2.0/24;
            deny 10.0.0.0/24;
            */}}
            {{- $serviceACLs := (or (index .ServiceMeta "nidito-acl") "") | replaceAll "; " ";" | split ";" }}
            {{- range $serviceACLs }}
              {{- $parts := . | replaceAll ", " "," | split " " }}
              {{- range (index $parts 1 | split ",") }}
            {{ index $parts 0 }} {{ scratch.Get (printf "network-%s" .) }};
              {{- end }}
            {{- end }}

            {{- if not (in .Tags "nidito.http.public") }}
            {{- scratch.MapSet "services" .Name "local" }}
            deny all;
            {{- else }}
            allow all;
            {{- scratch.MapSet "services" .Name "public" }}
            {{ end }}

            ssl_certificate     /ssl/star.crt;
            ssl_certificate_key /ssl/star.key;
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
              resolver 10.42.20.1 valid=30s;
              proxy_pass http://{{ .Address }}:{{ .Port }};
            }
          }

              {{- end }}
            {{- end }}
          {{- end }}

          {{- range $name, $data := (key "dns/static-entries" | parseJSON) }}
          {{- scratch.MapSet "services" $name "static" }}

          server {
            listen *:80;
            server_name {{ $name }} {{ $name }}.{{ scratch.Get "zone" }};
            return 301 https://{{ $name }}.{{ scratch.Get "zone" }};
          }
          server {
            listen *:443 ssl http2;
            server_name {{ $name }}.{{ scratch.Get "zone" }};

            allow 127.0.0.1;
            allow {{ scratch.Get "core-network-range" }};
            deny all;

            ssl_certificate     /ssl/star.crt;
            ssl_certificate_key /ssl/star.key;
            ssl_protocols       TLSv1.2;
            ssl_prefer_server_ciphers on;
            ssl_ciphers "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384";
            keepalive_timeout   70;

            location / {
              client_max_body_size 500m;
              add_header X-Edge {{ $nodeName }} always;
              add_header X-Nidito-Service {{ $name }} always;
              proxy_set_header Host $host;
              proxy_set_header X-Real-IP $remote_addr;
              proxy_set_header X-Forwarded-Proto $scheme;
              proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
              resolver 10.42.20.1 valid=30s;
              proxy_buffering "off";
              sendfile on;
              tcp_nopush on;
              tcp_nodelay on;
              proxy_pass https://{{ $name }}.service.consul:{{ $data.port }};
            }
          }

          {{- end}}

          server {
            listen *:443 ssl http2;
            server_name _
              {{ $nodeName }}.node.consul
              {{ $nodeName }}.node.{{ $dc }}.consul
              {{ $nodeName }}.{{ scratch.Get "zone" }};

            allow 127.0.0.1;
            allow {{ scratch.Get "core-network-range" }};
            deny all;
            root /var/lib/www;

            ssl_certificate     /ssl/star.crt;
            ssl_certificate_key /ssl/star.key;
            ssl_protocols       TLSv1.2;
            ssl_prefer_server_ciphers on;
            ssl_ciphers "ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-CHACHA20-POLY1305:ECDHE-RSA-CHACHA20-POLY1305:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA384";
            keepalive_timeout   70;

            location /nidito {
              allow 127.0.0.1;
              allow {{ scratch.Get "core-network-range" }};
              deny all;
              access_log off;
              default_type application/json;
            }

            location / {
              add_header X-Edge {{ $nodeName }} always;
              client_max_body_size 128k;
              default_type application/json;
              return 404 '{"message": "Not found"}';
            }
          }

          server {
            listen      *:80 default_server;
            server_name  _;
            root /var/lib/www;
            location /status {
              allow 127.0.0.1;
              allow {{ scratch.Get "core-network-range" }};
              deny all;
              stub_status;
              access_log off;
            }
            location /nidito {
              allow 127.0.0.1;
              allow {{ scratch.Get "core-network-range" }};
              deny all;
              access_log off;
              default_type application/json;
            }
            location / {
              client_max_body_size 128k;
              default_type application/json;
              return 404 '{"message": "Not found"}';
            }
          }

        NGINX
        change_mode   = "restart"
        splay = "5s"
      }

      config {
        image = "nginx:stable-alpine"
        network_mode = "host"

        ports = ["http", "https"]

        volumes = [
          "secrets/ssl:/ssl",
          "local/default.conf:/etc/nginx/conf.d/default.conf",
          "local/nidito:/var/lib/www/nidito"
        ]
      }

      resources {
        cpu    = 100
        memory = 128
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
          path     = "/status"
          interval = "60s"
          timeout  = "2s"
        }
      }
    }
  }
}
