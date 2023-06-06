{{- $consulAddr := (env "CONSUL_HTTP_ADDR") -}}
{{- $consulHost := (index ($consulAddr | trimPrefix "https://" | split ":") 0) -}}
{{- $consulPort := (index ($consulAddr | trimPrefix "https://" | split ":") 1) -}}
{{ with secret "consul-acl/creds/service-prometheus" -}}
{{- scratch.Set "consulToken" .Data.token }}
{{- end }}
scrape_configs:
  - job_name: network
    scrape_interval: 30s
    static_configs:
    - targets:
      # anahuac exporter
      - '10.42.20.1:9100'
      # claudqui exporter
      - '10.42.0.10:9130'

  # query dns SRV records to find node names
  # replace RPC port with known https port
  - job_name: consul-server
    scheme: https
    scrape_interval: 15s
    metrics_path: /v1/agent/metrics
    authorization:
      credentials: {{ scratch.Get "consulToken" }}
    params:
      format: ["prometheus"]
    dns_sd_configs:
      - names: ["consul.service.consul"]
        port: 5553
    relabel_configs:
      - source_labels: ['__address__']
        regex:         '([^.]+)\.node\..+\.consul:\d+'
        target_label:  'instance'
        replacement:   '$1'
      - source_labels: ['__address__']
        regex: '([^:]+):(\d+)'
        target_label: __address__
        replacement: '$1:{{ $consulPort }}'

  # pull host metrics from services tagged
  - job_name: host_metrics
    scrape_interval: 15s
    consul_sd_configs:
      - server: {{ $consulAddr }}
        datacenter: "{{ env "node.region" }}"
        token: {{ scratch.Get "consulToken" }}
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
      - server: "{{ $consulAddr }}"
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
      - source_labels: ['__meta_consul_service_metadata_nidito_metrics_scheme']
        regex: '(.+)'
        target_label: __scheme__
        replacement: '$1'
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
