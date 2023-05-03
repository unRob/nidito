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
        destination = "local/.mnamer-v2.json"
        data = <<-JSON
        {
          "api_key_omdb": null,
          "api_key_tmdb": "{{ with secret "cfg/svc/tree/nidi.to:tv-renamer" }}{{ .Data.tmdb.v3 }}{{ end }}",
          "api_key_tvdb": "{{ with secret "cfg/svc/tree/nidi.to:tv-renamer" }}{{ .Data.tvdb }}{{ end }}",
          "api_key_tvmaze": null,
          "batch": true,
          "episode_api": "tvdb",
          "episode_directory": "/media/tv-shows/{series}/Season {season:02}",
          "episode_format": "{series} - S{season:02}E{episode:02} - {title}.{extension}",
          "hits": 5,
          "ignore": [
              ".*sample.*",
              "^RARBG.*"
          ],
          "language": null,
          "lower": false,
          "mask": [
              ".avi",
              ".m4v",
              ".mp4",
              ".mkv",
              ".ts",
              ".wmv",
              ".srt",
              ".idx",
              ".sub"
          ],
          "movie_api": "tmdb",
          "movie_directory": "/media/movies",
          "movie_format": "{name} ({year}).{extension}",
          "no_guess": true,
          "no_overwrite": true,
          "no_style": false,
          "recurse": false,
          "replace_after": {
              "&": "and",
              ";": ",",
              "@": "at"
          },
          "replace_before": {},
          "scene": false,
          "verbose": true
        }
        JSON
      }

      template {
        destination = "local/entrypoint.sh"
        perms = 0777
        data = <<-SH
        #!/usr/bin/env sh

        if ! [ -z "$(ls -A /media/dropbox/tv-series)" ]; then
          echo "renaming tv-series"
          mnamer /media/dropbox/tv-series || exit 2
        else
          echo "no tv series to process"
        fi

        if ! [ -z "$(ls -A /media/dropbox/movies)" ]; then
          echo "renaming movies"
          mnamer /media/dropbox/movies || exit 2
        else
          echo "no movies to process"
        fi
        SH
      }

      config {
        image = "registry.nidi.to/tv-renamer:202305020307"
        command = "/${NOMAD_TASK_DIR}/entrypoint.sh"

        volumes = [
          "local/.mnamer-v2.json:/app/.mnamer-v2.json",
          "/volume1/media/:/media",
        ]
      }

      resources {
        cpu = 100
        memory = 300
        memory_max = 800
      }
    }
  }

}
