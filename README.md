# Orchestrator: Microservices Architecture with K3s

> **Project:** Orchestrator - A complete microservices architecture deployed in a K3s cluster using Vagrant and Kubernetes manifests.

## Overview
This project demonstrates the deployment, management, and scaling of a full microservices architecture within a lightweight Kubernetes cluster (K3s). It encompasses container orchestration, secure credentials handling via Kubernetes Secrets, horizontal scaling based on CPU consumption, and resilient stateful database deployments.

## Prerequisites
- **Vagrant:** Required for provisioning the virtual machines (master and agent nodes).
- **VirtualBox:** The provider used by Vagrant to run the VMs.
- **Docker Hub Account:** To pull the required images. (Images are provided in the manifests pointing to `yelmach/*`).
- **Bash Environment:** To execute the orchestration scripts.

## Project Structure
```console
.
├── Manifests/
│   ├── api-gateway.yaml
│   ├── inventory-app.yaml
│   ├── billing-app.yaml
│   ├── inventory-db.yaml
│   ├── billing-db.yaml
│   ├── rabbit-mq.yaml
│   └── secrets.yaml
├── Scripts/
│   ├── master.sh
│   └── agent.sh
├── .env.example
├── orchestrator.sh
└── Vagrantfile
```

## Configuration & Setup

### 1. Environment Variables
The system relies on an environment file to inject configurations securely. Create a `.env` file in the root directory (you can copy the provided `.env.example`).
```bash
cp .env.example .env
```
Ensure the variables are populated. The orchestrator script will read this file during manifest application.

### 2. Secrets Configuration
The `secrets.yaml` file securely stores database credentials. Do not hardcode passwords in application manifests. The orchestrator script uses `envsubst` to securely replace variables from your `.env` file into the manifests before applying them to the cluster.

## Usage & Orchestration
The `orchestrator.sh` script manages the entire lifecycle of the cluster and its deployments. It automatically installs `kubectl` if it is not present.

- **Create the cluster:** Provisions the VMs, installs K3s, and configures the environment.
  ```bash
  ./orchestrator.sh create
  ```
- **Start the cluster:** Boots up previously created VMs without running the provisioning scripts again.
  ```bash
  ./orchestrator.sh start
  ```
- **Apply Manifests:** Injects variables from the `.env` file and deploys all services to the cluster.
  ```bash
  ./orchestrator.sh apply
  ```
- **Stop the cluster:** Gracefully halts the VMs.
  ```bash
  ./orchestrator.sh stop
  ```
- **Destroy the cluster:** Destroys the VMs and cleans up configuration files.
  ```bash
  ./orchestrator.sh destroy
  ```

After creating or starting the cluster, configure your local `kubectl` by exporting the kubeconfig path:
```bash
export KUBECONFIG=$(pwd)/k3s.yaml
```

## Architecture Layout
- **api-gateway-app:** Exposed on host port `3000`. Routes traffic to inner services. Autoscales (1-3 replicas) based on CPU.
- **inventory-app:** Accessible internally on port `8080`. Connects to `inventory-db`. Autoscales (1-3 replicas) based on CPU.
- **inventory-db (PostgreSQL):** Deployed as a StatefulSet with persistent volumes. Port `5432`.
- **billing-app:** Deployed as a StatefulSet. Connects to `billing-db` and consumes messages from RabbitMQ.
- **billing-db (PostgreSQL):** Deployed as a StatefulSet with persistent volumes. Port `5432`.
- **rabbit-queue:** RabbitMQ server deployed as a StatefulSet with persistent volumes.

---

# Comprehensive Kubernetes Architecture & Networking Guide

## 1. Kubernetes High-Level Architecture
Kubernetes adheres to a decoupled, master-worker topology split into two functional layers: the **Control Plane** (the cluster's analytical brain) and the **Worker Nodes** (the cluster's execution system). This split ensures fault tolerance, horizontal scaling, and separation of concerns.

![image](./docs/k8s.png)

## 2. Control Plane & Worker Node Components

### The Control Plane (The Brain)
The Control Plane makes global decisions, monitors cluster health, and drives the cluster toward the desired state defined in YAML manifests.
* **`kube-apiserver`:** The synchronous core and front end of the Control Plane. It exposes the Kubernetes API and acts as the gatekeeper for all structural mutations. Every component communicates exclusively through the API Server.
* **`etcd`:** A distributed, consistent, highly available key-value store. It serves as the cluster's absolute source of truth.
* **`kube-scheduler`:** The logistical matchmaker. It scans for newly instantiated Pods that lack an assigned node and binds the Pod to the optimal worker node based on resources.
* **`kube-controller-manager`:** A single binary housing a suite of distinct, continuous background loops (controllers) that run a non-stop reconciliation cycle.

### The Worker Nodes (The Muscle)
Worker Nodes are the machines dedicated to executing containerized processes.
* **`kubelet`:** An agent running directly on the node's host OS. It acts as the local node captain, registering the node and interacting with the Container Runtime.
* **`kube-proxy`:** A network agent running on every node that implements the Kubernetes Service abstraction.
* **Container Runtime:** The engine responsible for low-level container isolation and lifecycle management (e.g., Docker, containerd).

## 3. Workload Abstractions: Pods, Deployments, and StatefulSets

### Pods
The **Pod** is the atomic building block of the Kubernetes object model. It represents a single runnable instance of an application. Pods are strictly **ephemeral and disposable**.

### Deployments vs. StatefulSets

| Operational Vector | Deployments | StatefulSets |
| :--- | :--- | :--- |
| **Target Workload** | **Stateless Apps** (e.g., API Gateways, Web Frontends). | **Stateful Apps** (e.g., PostgreSQL, RabbitMQ). |
| **Pod Naming Conventions** | Ephemeral, random hash suffixes. | Stable, deterministic, zero-indexed ordinals (e.g., `db-0`). |
| **Storage Association** | Shared or ephemeral storage. Replaced Pods do not preserve volume relationships. | **Sticky Storage**. Each ordinal Pod maps to its specific PersistentVolume. |
| **Network Identity** | Pods are anonymous and interchangeable. | Each Pod features a unique, predictable network DNS subdomain linked to a Headless Service. |

## 4. Kubernetes Networking & DNS Architecture
Kubernetes operates under a fundamental network requirement: Every Pod receives a unique, routable IP address within the cluster, and every Pod can communicate directly with any other Pod.

### CoreDNS: In-Cluster Service Discovery
Inside every cluster runs **CoreDNS**. When a Service named `inventory-service` is deployed in the namespace `default`, CoreDNS creates a Fully Qualified Domain Name (FQDN) mapping to its virtual IP (e.g., `inventory-service.default.svc.cluster.local`).

## 5. Services: ClusterIP vs. Headless Services

### Standard ClusterIP Services (Stateless Load Balancing)
A standard `ClusterIP` Service provides a single, permanent virtual IP address and port combination. `kube-proxy` handles proxying traffic to the backend pods.

### Headless Services (Stateful Topology Discovery)
For stateful clusters like databases or message brokers, centralized virtual IP routing is counterproductive. This is solved by setting `clusterIP: None` in the YAML declaration.
* **Bypassing Kube-Proxy:** No `ClusterIP` is generated, so `kube-proxy` ignores it.
* **DNS Direct Mapping:** CoreDNS directly returns the array of A records containing the real, underlying IP addresses of all healthy matching Pods.
* **Individual Pod Addressing:** When paired with a `StatefulSet`, CoreDNS generates explicit DNS entries for individual pod ordinals (e.g., `db-0.db-service.default.svc.cluster.local`).