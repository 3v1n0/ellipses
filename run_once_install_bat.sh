#!/bin/bash
set -e

if command -v bat &> /dev/null || command -v batcat &> /dev/null; then
  exit 0
fi

echo "Setting up bat..."

if ! command -v sudo &> /dev/null; then
  echo "No sudo, skipping bat setup..."
  exit 0
fi

if grep -qs debian /etc/os-release; then
  sudo apt-get -qy update
  sudo apt-get -y install bat
elif grep -qs fedora /etc/os-release; then
  sudo dnf -y install bat
fi

