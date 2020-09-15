job "tv-renamer" {
  datacenters = ["brooklyn"]
  type = "batch"

  group "tv-renamer" {

    task "tv-renamer" {
      driver = "docker"

      vault {
        policies = ["tv-renamer"]

        change_mode   = "signal"
        change_signal = "SIGHUP"
      }

      constraint {
        attribute = "${meta.nidito-storage}"
        value     = "primary"
      }

      template {
        data = <<-JSON
        {
          "batch": true,
          "episode_separator": "-",
          "episode_single": "%02d",
          "extension_pattern": "(\\.[a-zA-Z0-9]+)$",
          "filename_with_date_and_episode": "%(seriesname)s - %(episode)s - %(episodename)s%(ext)s",
          "filename_with_date_without_episode": "%(seriesname)s - %(episode)s%(ext)s",
          "filename_with_episode": "%(seriesname)s - S%(seasonnumber)02dE%(episode)s - %(episodename)s%(ext)s",
          "filename_with_episode_no_season": "%(seriesname)s - %(episode)s - %(episodename)s%(ext)s",
          "filename_without_episode": "%(seriesname)s - E%(seasonnumber)02dE%(episode)s%(ext)s",
          "filename_without_episode_no_season": "%(seriesname)s - %(episode)s%(ext)s",
          "verbose": true,
          "tvdb_api_key": "{{ with secret "kv/nidito/config/services/tvdb" }}{{ .Data.key }}{{ end }}"
        }
        JSON
        destination = "local/config.json"
      }

      config {
        image = "registry.nidi.to/tv-renamer:202009150407"

        volumes = [
          "local/config.json:/app/config.json",
          "/volume1/media/:/media",
        ]
      }

      resources {
        cpu = 100
        memory = 300
        network {
          mbits = 10
        }
      }
    }
  }

}
