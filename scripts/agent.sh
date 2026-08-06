#!/bin/bash

echo "Installing K3s Agent..."

# Read the master token from the shared vagrant folder
TOKEN=$(cat /vagrant/node-token)

# Install K3s agent and join the cluster using the master's IP and Token
curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.10:6443 K3S_TOKEN=$TOKEN sh -

curl -sfL https://get.k3s.io | K3S_URL=https://192.168.56.10:6443 K3S_TOKEN=$TOKEN sh -s - --flannel-iface eth1