# Terraform - Provision 3 GCP VMs for CloudEco Kubernetes Cluster
# Creates: 1 master node + 2 worker nodes
# Region: australia-southeast2-a
# Machine type: e2-standard-4 (4 vCPU, 16GB RAM) — matches assignment spec
#
# Usage:
#   1. Fill in your project_id in variables.tf
#   2. terraform init
#   3. terraform plan
#   4. terraform apply

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

# Configure the GCP provider
provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

# ── Firewall Rules ────────────────────────────────────────────────────────────

# Allow SSH from anywhere (port 22)
resource "google_compute_firewall" "allow_ssh" {
  name    = "cloudeco-allow-ssh"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s-node"]
}

# Allow Kubernetes API server (port 6443) so workers can join the master
resource "google_compute_firewall" "allow_k8s_api" {
  name    = "cloudeco-allow-k8s-api"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["6443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s-node"]
}

# Allow NodePort range (30000-32767) for external access to the CloudEco API
resource "google_compute_firewall" "allow_nodeport" {
  name    = "cloudeco-allow-nodeport"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["30000-32767"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["k8s-node"]
}

# Allow internal cluster traffic between all nodes (all ports)
resource "google_compute_firewall" "allow_internal" {
  name    = "cloudeco-allow-internal"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "udp"
    ports    = ["0-65535"]
  }

  allow {
    protocol = "icmp"
  }

  # Only allow traffic from within the VPC subnet
  source_ranges = ["10.0.0.0/8"]
  target_tags   = ["k8s-node"]
}

# ── Master Node ───────────────────────────────────────────────────────────────

resource "google_compute_instance" "k8s_master" {
  name         = "k8s-master"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["k8s-node", "k8s-master"]

  boot_disk {
    initialize_params {
      image = var.os_image   # Ubuntu 24.04 LTS
      size  = 50             # GB
    }
  }

  network_interface {
    network = "default"
    # Assign a public IP so we can SSH in from outside
    access_config {}
  }

  # SSH public key for zhangyanll
  metadata = {
    ssh-keys = "zhangyanll:${file(var.ssh_public_key_path)}"
  }
}

# ── Worker Node 1 ─────────────────────────────────────────────────────────────

resource "google_compute_instance" "k8s_worker1" {
  name         = "k8s-worker1"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["k8s-node", "k8s-worker"]

  boot_disk {
    initialize_params {
      image = var.os_image
      size  = 50
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "zhangyanll:${file(var.ssh_public_key_path)}"
  }
}

# ── Worker Node 2 ─────────────────────────────────────────────────────────────

resource "google_compute_instance" "k8s_worker2" {
  name         = "k8s-worker2"
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["k8s-node", "k8s-worker"]

  boot_disk {
    initialize_params {
      image = var.os_image
      size  = 50
    }
  }

  network_interface {
    network = "default"
    access_config {}
  }

  metadata = {
    ssh-keys = "zhangyanll:${file(var.ssh_public_key_path)}"
  }
}
