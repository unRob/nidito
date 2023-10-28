#!/usr/bin/env bash

echo "Gathering information on $NODE_NAME" >&2
os=$(uname -s)
arch=$(uname -m)

if [[ "$arch" == aarch64 ]]; then
  arch="arm64"
fi

case "$os" in
  "Linux")
    if [[ -f /etc/os-release ]]; then
      # plain old linux
      distro=$(awk -F= '/^ID/{gsub("\"", ""); v=tolower($2)} END {print v}' /etc/os-release)
    elif [[ -f /etc/VERSION ]]; then
      # synology
      distro=$(awk -F= '/^os_name/{gsub("\"", ""); v=tolower($2)} END {print v}' /etc/VERSION)
    fi
    os="linux/$distro"

    if [[ -f /sys/devices/virtual/dmi/id/product_name ]]; then
      model="$(awk '{print tolower($0)}' /sys/devices/virtual/dmi/id/product_name)"
    elif [[ -f "/proc/device-tree/model" ]]; then
      # raspberry pi
      model="$(awk '{
        gsub(" Model ", "");
        gsub(/([0-9]) (\w)$/, "$1$2");
        gsub(" ", "-");
        print tolower($0)}' /proc/device-tree/model)"
    fi

    if ! mac_address="$(ip -json a show | jq -r 'map(select(.link_type == "ether" and .operstate == "UP" and (.linkinfo // null) == null) | .address) | first')"; then
      echo "Unknown mac address for $NODE_NAME" >&2
      mac_address="00:00:00:00:00:00"
    fi
  ;;
  "Darwin")
    # hw.model: MacBookPro18,4
    model="$(sysctl hw.model | awk '{print tolower($2)}')"
    # 16.1
    version="$(sw_vers -productVersion | cut -d. -f1,2)"
    os="macos/$version"
    iface=$(route -n get default | awk '/interface/ {print $2}')
    mac_address=$(networksetup -getmacaddress "$iface" | awk '{print $3}')
  ;;
esac

echo "Detected $model ($os $arch) at $mac_address" >&2
echo "$model|$os|$arch|$mac_address"
