#!/usr/bin/env bash

set -e

# clean up
apt-get clean
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
