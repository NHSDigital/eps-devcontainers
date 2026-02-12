#!/usr/bin/env bash

set -e

# install non snap version of firefox
add-apt-repository -y ppa:mozillateam/ppa
cat <<EOF > /etc/apt/preferences.d/mozilla-firefox 
Package: *
Pin: release o=LP-PPA-mozillateam
Pin-Priority: 1001 
EOF

apt-get -y install firefox
