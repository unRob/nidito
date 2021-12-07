job "prometheus" {
  datacenters = ["casa"]
  type = "service"

  vault {
    policies = ["prometheus"]
    change_mode   = "restart"
  }

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

    network {
      port "http" {
        to = 9090
      }
    }

    task "prometheus" {
      driver = "docker"

      constraint {
        attribute = "${meta.storage}"
        value     = "primary"
      }

      template {
        destination = "secrets/tls/ca.pem"
        data = <<-PEM
        {{- with secret "nidito/config/services/ca" }}
        {{ .Data.cert }}
        {{- end }}
        PEM
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      # https://www.consul.io/docs/agent/options.html#telemetry-prometheus_retention_time
      template {
        change_mode = "restart"
        data = <<-YAML
          {{- with secret "nidito/config/services/consul/ports" }}
          {{- scratch.Set "consulPort" .Data.http }}
          {{- end }}
          {{- with secret "nidito/service/prometheus/consul" }}
          {{- scratch.Set "consulToken" .Data.token }}
          {{- end }}
          scrape_configs:
            - job_name: consul-server
              scrape_interval: 15s
              metrics_path: /v1/agent/metrics
              authorization:
                credentials: "{{ scratch.Get "consulToken" }}"
              params:
                format: ["prometheus"]
              dns_sd_configs:
                - names: ["consul.service.consul"]
                  port: {{ scratch.Get "consulPort" }}
              relabel_configs:
                - source_labels: ['__address__']
                  regex:         '([^.]+)\.node\..+\.consul:\d+'
                  target_label:  'instance'
                  replacement:   '$1'
                - source_labels: ['__address__']
                  regex: '([^:]+):(\d+)'
                  target_label: __address__
                  replacement: '$1:{{ scratch.Get "consulPort" }}'

            - job_name: host_metrics
              scrape_interval: 15s
              consul_sd_configs:
                - server: "consul.service.consul:{{ scratch.Get "consulPort" }}"
                  datacenter: "{{ env "node.region" }}"
                  token: "{{ scratch.Get "consulToken" }}"
                  tags:
                    - nidito.metrics.host
              relabel_configs:
                - source_labels: [__meta_consul_node]
                  regex:         '(.*)'
                  target_label: instance
                  replacement:   '$1'

            - job_name: consul-services
              scrape_interval: 15s
              consul_sd_configs:
                - server: "consul.service.consul:{{ scratch.Get "consulPort" }}"
                  datacenter: "{{ env "node.region" }}"
                  token: "{{ scratch.Get "consulToken" }}"
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
                  target_label: __scheme__
                  replacement: 'https'
                - source_labels: ['__meta_consul_tags']
                  regex: '.*,nidito\.metrics\.hc-prometheus-hack,.*'
                  target_label: __param_format
                  replacement: 'prometheus'
                - source_labels: ['__meta_consul_service']
                  regex:         '(.*)(-metrics)?'
                  target_label:  'service'
                  replacement:   '$1'
                - source_labels: ['__meta_consul_node']
                  regex:         '(.*)'
                  target_label:  'instance'
                  replacement:   '$1'
          YAML
        destination = "local/prometheus.yml"
      }

      config {
        image = "prom/prometheus:v2.29.2"
        ports = ["http"]

        volumes = [
          "/nidito/prometheus:/var/lib/prometheus",
          "secrets/tls/ca.pem:/etc/ssl/certs/nidito.crt",
        ]

        args = [
          "--config.file=/local/prometheus.yml",
          "--storage.tsdb.path=/var/lib/prometheus",
          "--enable-feature=remote-write-receiver",
          "--web.console.libraries=/usr/share/prometheus/console_libraries",
          "--web.console.templates=/usr/share/prometheus/consoles",
          "--web.enable-admin-api",
        ]
      }

      resources {
        cpu    = 100
        memory = 200
      }

      service {
        name = "prometheus"
        port = "http"

        tags = [
          "nidito.infra",
          "nidito.dns.enabled",
          "nidito.metrics.enabled",
          "nidito.http.enabled",
        ]

        meta {
          nidito-acl = "allow altepetl"
        }

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
