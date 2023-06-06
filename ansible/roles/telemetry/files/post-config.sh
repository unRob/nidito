#!/bin/bash

cp /config/node_exporter/node_exporter.service /etc/systemd/system/node_exporter.service
systemctl enable --now node_exporter
systemctl restart node_exporter
