job "dns-update" {
  datacenters = ["brooklyn"]
  type = "batch"

  parameterized {
    payload = "required"
  }

  vault {
    policies = ["dns-update"]

    change_mode   = "signal"
    change_signal = "SIGHUP"
  }

  group "dns-update" {

    task "doctl" {
      driver = "raw_exec"

      template {
        data = <<EOF
{{ with secret "kv/nidito/config/dns/external/provider" }}
DIGITALOCEAN_ACCESS_TOKEN="{{ .Data.token }}"
{{ end }}
EOF
        destination = "secrets/file.env"
        env         = true
      }

      dispatch_payload {
        file = "ip.txt"
      }

      template {
        data = <<SH
#!/usr/bin/env bash
new_ip=$(cat local/ip.txt)
echo "Updating record to $new_ip"

{{ with secret "kv/nidito/config/dns" }}
zone="{{ .Data.zone" }}"
{{ end }}
{{ with secret "kv/nidito/config/dns/external/provider" }}
record="{{ .Data.record-id }}"
{{ end }}

exec curl --fail \
  -H 'Content-type: application/json' \
  -H "Authorization: Bearer $DIGITALOCEAN_ACCESS_TOKEN" \
  -X PUT \
  https://api.digitalocean.com/v2/domains/$zone/records/$record \
  -d@- <<JSON
{
  "type": "A",
  "data": "$new_ip",
  "name": "@",
  "ttl": 300
}
JSON
SH
        destination = "local/entrypoint.sh"
        perms = 750
      }

      config {
        command = "./local/entrypoint.sh"
      }

      resources {
        cpu = 20
        memory = 30
        network {
          mbits = 10
        }
      }
    }
  }

}
