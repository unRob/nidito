#!/bin/bash

cp {{ coredns.bin | dirname }}/coredns.service /etc/systemd/system/coredns.service
systemctl enable --now coredns
systemctl restart coredns
