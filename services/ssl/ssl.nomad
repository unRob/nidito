job "ssl" {
  datacenters = ["casa", "nyc1"]
  type = "batch"

  periodic {
    cron = "@weekly"
    prohibit_overlap = true
  }

  vault {
    policies = ["ssl"]
    change_mode   = "restart"
  }

  group "ssl" {

    task "ssl" {
      driver = "docker"

      template {
        destination = "secrets/env"
        data = <<-ENV
          VAULT_ADDR={{ env "VAULT_ADDR" }}
          CONSUL_HTTP_ADDR={{ env "CONSUL_HTTP_ADDR" }}
          {{ with secret "consul-acl/creds/service-ssl" -}}
          CONSUL_HTTP_TOKEN={{ .Data.token }}
          {{- end }}
        ENV
        env = true
      }

      config {
        image = "registry.nidi.to/ssl:202201042218"
        command = "{{ env 'node.region' }}"
      }

      resources {
        cpu = 10
        memory = 100
      }
    }
  }
}
