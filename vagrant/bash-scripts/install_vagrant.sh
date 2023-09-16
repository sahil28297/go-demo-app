#!/bin/bash

# Check if Homebrew is already installed
if ! command -v brew &>/dev/null; then
  echo "Homebrew is not installed. Installing..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh)"
else
  echo "Homebrew is already installed."
fi

# Check if Vagrant is already installed
if ! command -v vagrant &>/dev/null; then
  echo "Vagrant is not installed. Installing..."
  brew install --cask vagrant
else
  echo "Vagrant is already installed."
fi

# Check if VirtualBox is already installed
if ! command -v VirtualBox &>/dev/null; then
  echo "VirtualBox is not installed. Installing..."
  brew tap homebrew/cask-versions
  brew install virtualbox-beta
else
  echo "VirtualBox is already installed."
fi

echo "Setup completed."
