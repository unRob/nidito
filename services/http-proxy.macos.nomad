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
      attempts = 10
      # during
      interval = "5m"
      # waiting after a crash
      delay = "25s"
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
        destination = "local/mime.types"
        data = <<NGINX
types {
    text/html                                        html htm shtml;
    text/css                                         css;
    text/xml                                         xml;
    image/gif                                        gif;
    image/jpeg                                       jpeg jpg;
    application/javascript                           js;
    application/atom+xml                             atom;
    application/rss+xml                              rss;

    text/mathml                                      mml;
    text/plain                                       txt;
    text/vnd.sun.j2me.app-descriptor                 jad;
    text/vnd.wap.wml                                 wml;
    text/x-component                                 htc;

    image/png                                        png;
    image/svg+xml                                    svg svgz;
    image/tiff                                       tif tiff;
    image/vnd.wap.wbmp                               wbmp;
    image/webp                                       webp;
    image/x-icon                                     ico;
    image/x-jng                                      jng;
    image/x-ms-bmp                                   bmp;

    font/woff                                        woff;
    font/woff2                                       woff2;

    application/java-archive                         jar war ear;
    application/json                                 json;
    application/mac-binhex40                         hqx;
    application/msword                               doc;
    application/pdf                                  pdf;
    application/postscript                           ps eps ai;
    application/rtf                                  rtf;
    application/vnd.apple.mpegurl                    m3u8;
    application/vnd.google-earth.kml+xml             kml;
    application/vnd.google-earth.kmz                 kmz;
    application/vnd.ms-excel                         xls;
    application/vnd.ms-fontobject                    eot;
    application/vnd.ms-powerpoint                    ppt;
    application/vnd.oasis.opendocument.graphics      odg;
    application/vnd.oasis.opendocument.presentation  odp;
    application/vnd.oasis.opendocument.spreadsheet   ods;
    application/vnd.oasis.opendocument.text          odt;
    application/vnd.openxmlformats-officedocument.presentationml.presentation
                                                     pptx;
    application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
                                                     xlsx;
    application/vnd.openxmlformats-officedocument.wordprocessingml.document
                                                     docx;
    application/vnd.wap.wmlc                         wmlc;
    application/x-7z-compressed                      7z;
    application/x-cocoa                              cco;
    application/x-java-archive-diff                  jardiff;
    application/x-java-jnlp-file                     jnlp;
    application/x-makeself                           run;
    application/x-perl                               pl pm;
    application/x-pilot                              prc pdb;
    application/x-rar-compressed                     rar;
    application/x-redhat-package-manager             rpm;
    application/x-sea                                sea;
    application/x-shockwave-flash                    swf;
    application/x-stuffit                            sit;
    application/x-tcl                                tcl tk;
    application/x-x509-ca-cert                       der pem crt;
    application/x-xpinstall                          xpi;
    application/xhtml+xml                            xhtml;
    application/xspf+xml                             xspf;
    application/zip                                  zip;

    application/octet-stream                         bin exe dll;
    application/octet-stream                         deb;
    application/octet-stream                         dmg;
    application/octet-stream                         iso img;
    application/octet-stream                         msi msp msm;

    audio/midi                                       mid midi kar;
    audio/mpeg                                       mp3;
    audio/ogg                                        ogg;
    audio/x-m4a                                      m4a;
    audio/x-realaudio                                ra;

    video/3gpp                                       3gpp 3gp;
    video/mp2t                                       ts;
    video/mp4                                        mp4;
    video/mpeg                                       mpeg mpg;
    video/quicktime                                  mov;
    video/webm                                       webm;
    video/x-flv                                      flv;
    video/x-m4v                                      m4v;
    video/x-mng                                      mng;
    video/x-ms-asf                                   asx asf;
    video/x-ms-wmv                                   wmv;
    video/x-msvideo                                  avi;
}
NGINX
      }

      template {
        destination = "local/nginx.conf"
        data = <<NGINX
daemon off;
user  _wwwproxy;
worker_processes  auto;

events {
    worker_connections  1024;
}


http {
    include       mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

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
{{- $secretsDir := env "NOMAD_SECRETS_DIR"}}
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

  ssl_certificate     {{ $secretsDir }}/ssl/star.nidi.to.crt;
  ssl_certificate_key {{ $secretsDir }}/ssl/star.nidi.to.key;
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
}
NGINX
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      config {
        command = "/usr/local/bin/nginx"
        args = [
          "-c", "${NOMAD_TASK_DIR}/nginx.conf"
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
