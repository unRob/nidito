job "tv-renamer" {
  datacenters = ["casa"]
  type = "batch"

  vault {
    policies = ["tv-renamer"]
    change_mode   = "restart"
  }

  parameterized {}

  group "tv-renamer" {

    task "tv-renamer" {
      driver = "docker"

      constraint {
        attribute = "${meta.storage}"
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
          "tvdb_api_key": "{{ with secret "cfg/svc/tree/nidi.to:tv-renamer" }}{{ .Data.tvdb }}{{ end }}"
        }
        JSON
        destination = "local/config.json"
      }

      config {
        image = "registry.nidi.to/tv-renamer:202201042218"

        volumes = [
          "local/config.json:/app/config.json",
          "/volume1/media/:/media",
        ]
      }

      resources {
        cpu = 100
        memory = 300
      }
    }
  }

}
