#!/bin/bash

cp {{ coredns.bin | dirname }}/coredns.service {{ systemd.prefix }}/systemd/system/coredns.service
systemctl enable --now coredns
systemctl restart coredns
