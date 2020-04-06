job "dns-update" {
  datacenters = ["brooklyn"]
  type = "batch"

  parameterized {
    payload = "required"
  }

  group "dns-update" {

    task "doctl" {
      driver = "raw_exec"

      template {
        data = <<EOF
DIGITALOCEAN_ACCESS_TOKEN="{{ key "/nidito/config/dns/external/provider/token" }}"
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

zone="{{ key "/nidito/config/dns/zone" }}"
record="{{ key "/nidito/config/dns/external/provider/record-id" }}"

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
