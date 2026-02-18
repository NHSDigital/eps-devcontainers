#!/usr/bin/env bash
set -e
export DEBIAN_FRONTEND=noninteractive

# clean up
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
