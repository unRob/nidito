job "icecast" {
  datacenters = ["casa"]
  priority = 50

  group "icecast" {
    reschedule {
      delay          = "5s"
      delay_function = "fibonacci"
      max_delay      = "1h"
      unlimited      = true
    }

    restart {
      attempts = 10
      interval = "10m"
      delay = "10s"
      mode = "delay"
    }

    network {
      port "http" {
        to = 8000
        static = 8000
      }
    }

    task "radio" {
      driver = "docker"
      user = "icecast"

      vault {
        policies = ["icecast"]

        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      constraint {
        attribute = "${meta.nidito-storage}"
        value     = "primary"
      }

      template {
        destination = "local/icecast.xml"
        data = <<XML
{{- with secret "kv/nidito/config/dns" }}
{{- scratch.Set "zone" .Data.zone }}
{{-  end }}
<icecast>
    <location>Earth</location>
    <admin>icecast@{{ scratch.Get "zone" }}</admin>

    <limits>
        <clients>300</clients>
        <sources>2</sources>
        <queue-size>524288</queue-size>
        <client-timeout>30</client-timeout>
        <header-timeout>15</header-timeout>
        <source-timeout>60</source-timeout>
        <burst-size>65535</burst-size>
    </limits>

    <authentication>
        {{- with secret "kv/nidito/config/services/icecast/credentials" }}
        <source-password>{{ .Data.source }}</source-password>
        <relay-password>{{ .Data.source }}</relay-password>

        <admin-user>admin</admin-user>
        <admin-password>{{ .Data.admin }}</admin-password>
        {{- end }}
    </authentication>

    <hostname>{{ env "NOMAD_TASK_NAME" }}.{{ scratch.Get "zone" }}</hostname>

    <listen-socket><port>8000</port></listen-socket>

    <mount type="normal">
        <mount-name>/practicando.*</mount-name>
        <dump-file>/recordings/%Y-%m-%d.%H-%M-%S.${mount}</dump-file>
        <!-- <fallback-mount>/example2.ogg</fallback-mount> -->
        <!-- <fallback-override>1</fallback-override> -->
        <!-- <fallback-when-full>1</fallback-when-full> -->
        <!-- <intro>/example_intro.ogg</intro> -->
        <!-- <hidden>1</hidden> -->
        <!-- <on-connect>/home/icecast/bin/stream-start</on-connect> -->
        <on-disconnect>/usr/share/icecast/on-disconnect.sh</on-disconnect>
    </mount>

    <mount type="normal">
        <mount-name>/presenta.*</mount-name>
        <dump-file>/recordings/%Y-%m-%d.%H-%M-%S.${mount}</dump-file>
        <on-disconnect>/usr/share/icecast/on-disconnect.sh</on-disconnect>
    </mount>

    <mount type="normal">
        <mount-name>/jugando.*</mount-name>
    </mount>

    <fileserve>1</fileserve>

    <paths>
        <x-forwarded-for>10.10.0.2</x-forwarded-for>
        <!-- basedir is only used if chroot is enabled -->
        <basedir>/usr/share/icecast</basedir>

        <!-- Note that if <chroot> is turned on below, these paths must both be relative to the new root, not the original root -->
        <logdir>/var/log/icecast</logdir>
        <webroot>/usr/share/icecast/web</webroot>
        <adminroot>/usr/share/icecast/admin</adminroot>
        <!-- <pidfile>/usr/share/icecast/icecast.pid</pidfile> -->

        <alias source="/" dest="/index.html"/>
        <alias source="/play.html" dest="/play.html"/>
        <alias source="/status.json" dest="/status-json.xsl"/>
    </paths>

    <logging>
        <accesslog>-</accesslog>
        <errorlog>-</errorlog>
        <!-- <playlistlog>playlist.log</playlistlog> -->
        <loglevel>3</loglevel> <!-- 4 Debug, 3 Info, 2 Warn, 1 Error -->
        <logsize>10000</logsize> <!-- Max size of a logfile -->
    </logging>

    <security>
        <chroot>0</chroot>
        <changeowner>
            <user>icecast</user>
            <group>icecast</group>
        </changeowner>
    </security>
</icecast>

XML
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }


      template {
        destination = "local/minio-env.sh"
        data = <<SHELL
#!/usr/bin/env sh
{{- with secret "kv/nidito/config/dns" }}
{{- scratch.Set "zone" .Data.zone }}
{{-  end }}
{{- with secret "kv/nidito/config/services/minio" }}
export MC_HOST_cajon="https://{{ .Data.key }}:{{ .Data.secret }}@cajon.{{ scratch.Get "zone" }}/"
{{- end }}
export MC_CONFIG_DIR="/home/icecast/.mc"
        SHELL
        perms = "777"
        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      config {
        image = "registry.nidi.to/icecast:202105150228”

        ports = ["http"]

        volumes = [
          "local/icecast.xml:/etc/icecast.xml",
          "local/minio-env.sh:/home/icecast/minio-env.sh",
          "/nidito/icecast:/recordings"
        ]
      }

      resources {
        cpu    = 100
        memory = 128
      }

      service {
        name = "radio"
        port = "http"

        tags = [
          "nidito.service",
          "nidito.dns.enabled",
          "nidito.http.enabled",
          "nidito.http.public",
          "nidito.ingress.enabled",
        ]

        meta {
          nidito-allowed-networks = "external"
          nidito-acl = "allow external"
          nidito-http-buffering = "off"
        }

        check {
          type     = "http"
          path     = "/status.json"
          interval = "30s"
          timeout  = "2s"

          check_restart {
            limit = 10
            grace = "15s"
            ignore_warnings = false
          }
        }
      }

    }
  }
}
