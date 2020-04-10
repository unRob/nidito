job "prometheus" {
  datacenters = ["brooklyn"]
  type = "service"

  group "prometheus" {
    reschedule {
      delay          = "5s"
      delay_function = "fibonacci"
      max_delay      = "1h"
      unlimited      = true
    }

     restart {
      attempts = 10
      interval = "5m"
      delay    = "25s"
      mode     = "delay"
    }


    task "prometheus" {
      driver = "docker"

      constraint {
        attribute = "${meta.hardware}"
        operator  = "="
        value     = "[[ consulKey "/nidito/config/nodes/chapultepec/hardware" ]]"
      }

      # https://www.consul.io/docs/agent/options.html#telemetry-prometheus_retention_time
      template {
        change_mode = "restart"
        data = <<EOF
scrape_configs:
  - job_name: consul-server
    scrape_interval: 15s
    metrics_path: /v1/agent/metrics
    params:
      format: ["prometheus"]
    dns_sd_configs:
      - names: ["consul.service.consul"]
        port: [[ consulKey "/nidito/config/consul/ports/http" ]]

    relabel_configs:
      - source_labels: ['__address__']
        regex:         '([^.]+)\.node\..+\.consul:\d+'
        target_label:  'instance'
        replacement:   '$1'
      - source_labels: ['__address__']
        regex: '([^:]+):(\d+)'
        target_label: __address__
        replacement: '$1:[[ consulKey "/nidito/config/consul/ports/http" ]]'

  - job_name: consul-services
    scrape_interval: 15s

    consul_sd_configs:
      - server: "consul.service.consul:[[ consulKey "/nidito/config/consul/ports/http" ]]"
        datacenter: brooklyn
        token: "[[ consulKey "/nidito/service/prometheus/consul/token" ]]"
        tags:
          - nidito.metrics.enabled

    relabel_configs:
      - source_labels: ['__meta_consul_tags']
        # drop nomad's non-http services
        regex: ',(rpc|serf),(.*)'
        action: drop
      - source_labels: ['__meta_consul_tags']
        regex: '.*,nidito\.metrics\.path=([^,]+),.*'
        target_label: __metrics_path__
        replacement: '$1'
      - source_labels: ['__address__', '__meta_consul_tags']
        regex: '([^:]+)(?::\d+)?;.*,nidito\.metrics\.port=([^,]+),.*'
        target_label: __address__
        replacement: '$1:$2'
      - source_labels: ['__meta_consul_tags']
        regex: '.*,nidito\.metrics\.hc-prometheus-hack,.*'
        target_label: __param_format
        replacement: 'prometheus'
      - source_labels: ['__meta_consul_service']
        regex:         '(.*)(-metrics)?'
        target_label:  'job'
        replacement:   '$1'
      - source_labels: ['__meta_consul_node']
        regex:         '(.*)'
        target_label:  'instance'
        replacement:   '$1'
EOF
        destination = "local/prometheus.yml"
      }

      config {
        image = "prom/prometheus:v2.17.1"
        port_map {
          http = 9090
        }

        volumes = [
          "/nidito/data/prometheus:/var/lib/prometheus",
        ]

        args = [
          "--config.file=/local/prometheus.yml",
          "--storage.tsdb.path=/var/lib/prometheus",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
          "--web.enable-admin-api",
        ]
      }

      resources {
        cpu    = 100
        memory = 200

        network {
          port "http" {}
        }
      }

      service {
        name = "prometheus"
        port = "http"

        tags = [
          "nidito.infra",
          "nidito.dns.enabled",
          "nidito.metrics.enabled",
          "traefik.enable=true",

          "traefik.http.routers.prometheus.rule=Host(`prometheus.[[ consulKey "/nidito/config/dns/zone" ]]`)",
          "traefik.http.routers.prometheus.entrypoints=http,https",
          "traefik.http.routers.prometheus.tls=true",
          "traefik.http.routers.prometheus.middlewares=trusted-network@consul,https-only@consul",
        ]

        check {
          type = "http"
          path = "/targets"
          interval = "10s"
          timeout = "2s"
        }
      }


    }
  }
}
