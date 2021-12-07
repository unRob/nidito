#!/bin/bash

cp /config/coredns/coredns.service /etc/systemd/system/coredns.service
systemctl enable coredns --now
systemctl restart coredns
