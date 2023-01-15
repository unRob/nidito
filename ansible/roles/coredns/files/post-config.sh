#!/bin/bash

cp /config/coredns/coredns.service /etc/systemd/system/coredns.service
systemctl enable --now coredns
systemctl restart coredns
