#!/bin/bash

cp /config/coredns/coredns.service /etc/systemd/system/coredns.service
systemctl enable coredns --now
systemctl reload-or-restart coredns

exit 0
