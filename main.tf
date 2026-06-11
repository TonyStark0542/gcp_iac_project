# ==========================================
# 1. PROVIDER & PROJECT BOOTSTRAPPING
# ==========================================
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  # No hardcoded project or region names. 
  # Set these via environment variables or replace with your actual IDs.
  project = var.gcp_project_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

# Variables for easy configuration
variable "gcp_project_id" {
  type        = string
  description = "The GCP Project ID where resources will live."
}

variable "gcp_region" {
  type    = string
  default = "us-central1"
}

variable "gcp_zone" {
  type    = string
  default = "us-central1-a"
}

variable "gcp_username" {
  type        = string
  description = "The active lab username extracted from gcloud."
}

# ==========================================
# 2. API ACTIVATION & DATA LOOKUPS
# ==========================================

# Enable the Compute Engine API automatically
resource "google_project_service" "compute_api" {
  project            = var.gcp_project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

# Grabs the configuration details of the active gcloud authenticated session
data "google_client_config" "current" {}

# ==========================================
# 3. FIREWALL RULE (Targeting Tags)
# ==========================================

resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-80"
  network = "default" # Utilizing the default VPC network

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web-server"] # This matches the tags on the instances
}

# ==========================================
# 4. COMPUTE INSTANCES (Multi-OS)
# ==========================================

# Ubuntu 22.04 LTS Instance
resource "google_compute_instance" "ubuntu_vm" {
  name         = "web-ubuntu-2204"
  machine_type = "e2-micro"
  zone         = var.gcp_zone
  tags         = ["http-server","web-server"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP for Ansible
    }
  }

  metadata = {
    # No more messy data block slicing. Natively uses the clean variable string.
    ssh-keys = "${var.gcp_username}:${file("~/.ssh/id_rsa.pub")}"
  }

  service_account {
    # FIX: Hardcode "default" so it pulls the runtime identity without needing the deleted data block
    email  = "default"
    scopes = ["cloud-platform"]
  }

  depends_on = [google_project_service.compute_api]
}

# Red Hat Enterprise Linux (RHEL) Instance
resource "google_compute_instance" "rhel_vm" {
  name         = "web-rhel-9"
  machine_type = "e2-micro"
  zone         = var.gcp_zone
  tags         = ["http-server","web-server"]

  boot_disk {
    initialize_params {
      image = "rhel-cloud/rhel-9"
    }
  }

  network_interface {
    network = "default"
    access_config {
      // Ephemeral public IP for Ansible
    }
  }

  metadata = {
    # No more messy data block slicing. Natively uses the clean variable string.
    ssh-keys = "${var.gcp_username}:${file("~/.ssh/id_rsa.pub")}"
  }

  service_account {
    # FIX: Hardcode "default" here as well
    email  = "default"
    scopes = ["cloud-platform"]
  }

  depends_on = [google_project_service.compute_api]
}

# ==========================================
# 5. OUTPUTS (For Ansible Handover)
# ==========================================
output "ubuntu_public_ip" {
  value       = google_compute_instance.ubuntu_vm.network_interface[0].access_config[0].nat_ip
  description = "Public IP of the Ubuntu node"
}

output "rhel_public_ip" {
  value       = google_compute_instance.rhel_vm.network_interface[0].access_config[0].nat_ip
  description = "Public IP of the RHEL node"
}