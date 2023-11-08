job "consul-backup" {
  datacenters = ["casa", "qro0"]
  type        = "batch"
  priority    = 50

  periodic {
    crons             = ["@daily"]
    prohibit_overlap = true
  }

  group "consul-backup" {
    vault {
      policies    = ["consul-backup"]
      change_mode = "noop"
    }

    task "consul-backup" {
      driver = "docker"

      template {
        destination   = "secrets/tls/ca.pem"
        data          = <<-PEM
        {{- with secret "cfg/infra/tree/service:ca" }}
        {{ .Data.cert }}
        {{- end }}
        PEM
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      template {
        env         = true
        destination = "secrets/env"
        data        = <<-EOF
          {{- with secret "cfg/svc/tree/nidi.to:consul-backup" }}
          MC_HOST_backups="https://{{ .Data.auth.key }}:{{ .Data.auth.secret }}@{{ .Data.storage.endpoint }}/"
          BACKUP_BUCKET={{ .Data.storage.bucket }}
          AGE_PUBLIC_KEY={{ .Data.keypair.public }}
          {{- end }}
          CONSUL_HTTP_ADDR={{ env "CONSUL_HTTP_ADDR" }}
          {{ with secret "cfg/infra/tree/service:consul" -}}
          CONSUL_HTTP_TOKEN={{ .Data.token }}
          {{- end }}
        EOF
      }

      resources {
        cpu        = 100
        memory     = 50
        memory_max = 500
      }

      config {
        image = "registry.nidi.to/consul-backup:202304092241"
        args  = ["${node.region}"]
        volumes = [
          "secrets/tls/ca.pem:/etc/ssl/certs/nidito.crt",
        ]
      }
    }

  }
}
