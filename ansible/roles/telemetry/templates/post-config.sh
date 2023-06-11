#!/bin/bash

cp {{ node_exporter.bin | dirname }}/node-exporter.service /etc/systemd/system/node-exporter.service
systemctl enable --now node-exporter
systemctl restart node-exporter
