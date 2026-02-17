#!/bin/bash
set -eo pipefail

# Normalize version (strip leading 'v')
version="${1#v}"
filename="dive_${version}_linux_amd64.deb"

# Download the specific debian package from GitHub releases
curl -fsOL "https://github.com/wagoodman/dive/releases/download/v${version}/${filename}"

# Install the package and clean up the installer file
sudo apt install ./"$filename"
rm "$filename"
