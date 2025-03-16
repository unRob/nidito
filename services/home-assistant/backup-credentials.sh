#!/bin/bash

{{ with secret "cfg/svc/tree/nidi.to:home-assistant" }}
export RCLONE_CONFIG_REMOTE_TYPE="s3"
export RCLONE_CONFIG_REMOTE_PROVIDER="Other"
export RCLONE_CONFIG_REMOTE_ENV_AUTH="false"
export RCLONE_CONFIG_REMOTE_ACCESS_KEY_ID="{{ .Data.storage.config.key }}"
export RCLONE_CONFIG_REMOTE_SECRET_ACCESS_KEY="{{ .Data.storage.config.secret }}"
export RCLONE_CONFIG_REMOTE_ENDPOINT="s3.garage.nidi.to"
export RCLONE_CONFIG_REMOTE_FORCE_PATH_STYLE="true"
export RCLONE_CONFIG_REMOTE_REGION="garage"
export BUCKET="{{ .Data.storage.config.bucket }}"
{{ end }}
