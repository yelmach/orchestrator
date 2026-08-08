#!/bin/bash

set -e

ensure_kubectl() {
  if command -v kubectl >/dev/null 2>&1; then
    echo "✅ kubectl is already installed at: $(command -v kubectl)"
  else
    echo "⏳ kubectl not found. Installing kubectl..."
    
    KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)
    
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    
    chmod +x kubectl
    
    mv kubectl "$HOME/.local/bin/"
    echo "✅ kubectl successfully installed to $HOME/.local/bin/"
    
    export PATH="$HOME/.local/bin:$PATH"
    
    # Alert if the local bin is missing from the permanent PATH
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo "⚠️ WARNING: $HOME/.local/bin is not in your system PATH."
        echo "   Please run the following command to add it permanently:"
        echo '   echo "export PATH=\$HOME/.local/bin:\$PATH" >> ~/.zshrc && source ~/.zshrc'
    fi
  fi
}

apply_manifests() {
  echo "⏳ Injecting environment variables and applying manifests..."

  if [ ! -f .env ]; then
    echo "❌ ERROR: .env file not found! Please create your .env file before deploying."
    exit 1
  fi

  set -a
  source .env
  set +a
  
  for file in manifests/*.yaml; do
    echo "Processing $file..."
    envsubst < "$file" | kubectl apply -f -
  done

  echo "✅ All manifests applied successfully."
}

create_cluster() {
  echo "Preparing cubectl environment..."
  ensure_kubectl
  
  vagrant up
  echo "cluster created"

  echo "Exporting kubeconfig for local access..."
  export KUBECONFIG="$(pwd)/k3s.yaml"
  echo "✅ Run 'export KUBECONFIG=\$(pwd)/k3s.yaml' in your terminal to use kubectl."
}

start_cluster() {
  vagrant up --no-provision
  echo "cluster started"
  echo "✅ Run 'export KUBECONFIG=\$(pwd)/k3s.yaml' in your terminal to use kubectl."
}

stop_cluster() {
  vagrant halt
  echo "cluster stopped"
}

destroy_cluster() {
  echo "Destroying Vagrant machines..."
  vagrant destroy -f
  
  echo "Cleaning up cluster configuration files..."
  rm -f k3s.yaml node-token
  
  echo "cluster destroyed"
}

case "$1" in
  create)
    create_cluster
    ;;
  start)
    start_cluster
    ;;
  stop)
    stop_cluster
    ;;
  destroy)
    destroy_cluster
    ;;
  apply)
    apply_manifests
    ;;
  *)
    echo "Usage: $0 {create|start|stop|destroy}"
    exit 1
    ;;
esac