#!/usr/bin/env bash

if [[ $1 == "start" ]]; then
  set -x
  # make sure our well-known folder is not wiped out by updates
  ln -sfv /volume1/nidito/ /nidito/
  # free ports 80/443
  sed -i -e 's/80/81/' -e 's/443/444/' /usr/syno/share/nginx/server.mustache /usr/syno/share/nginx/DSM.mustache /usr/syno/share/nginx/WWWService.mustache

  synoservicecfg --restart nginx || true
fi
