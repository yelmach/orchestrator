#!/bin/bash

echo "Installing K3s Master..."

curl -sfL https://get.k3s.io | sh -s - --flannel-iface eth1 --node-taint "node-role.kubernetes.io/master=true:NoSchedule"

# Export the node token so the agent can use it to join
cp /var/lib/rancher/k3s/server/node-token /vagrant/node-token

# Export the kubeconfig to the host machine
cp /etc/rancher/k3s/k3s.yaml /vagrant/k3s.yaml

# Update the kubeconfig IP so you can run kubectl from your host machine
sed -i 's/127.0.0.1/192.168.56.10/g' /vagrant/k3s.yaml