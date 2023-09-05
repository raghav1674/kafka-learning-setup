#!/usr/bin/env bash

sudo tee -a  /etc/yum.conf <<EOF
ip_resolve=4
EOF