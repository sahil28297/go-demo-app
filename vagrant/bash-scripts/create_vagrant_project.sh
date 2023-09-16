#!/bin/bash

# Check if Vagrant is installed
if ! command -v vagrant &>/dev/null; then
  echo "Vagrant is not installed. Please run the install_vagrant.sh script to install Vagrant first."
  exit 1
fi

# Check if VirtualBox is installed
if ! command -v VBoxManage &>/dev/null; then
  echo "VirtualBox is not installed. Please install VirtualBox before setting up the VM."
  exit 1
fi

# Change directory for your Vagrant project where Vagrantfile is defined
cd ..

# Start the VM with Vagrant
vagrant up

# Run the Ansible playbook to configure the VM
vagrant provision


echo "Vagrant Ubuntu VM for zerodha-demo-app setup completed."