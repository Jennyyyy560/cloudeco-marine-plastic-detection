# Terraform Variables for CloudEco GCP Infrastructure

variable "project_id" {
  description = "GCP Project ID"
  type        = string
  default     = "cloudeco-k8s"
}

variable "region" {
  description = "GCP region"
  type        = string
  default     = "australia-southeast2"
}

variable "zone" {
  description = "GCP zone"
  type        = string
  default     = "australia-southeast2-a"
}

variable "machine_type" {
  description = "VM machine type — e2-standard-4 = 4 vCPU / 16GB RAM"
  type        = string
  default     = "e2-standard-4"
}

variable "os_image" {
  description = "Boot disk image — Ubuntu 24.04 LTS"
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2404-lts-amd64"
}

variable "ssh_public_key_path" {
  description = "Path to SSH public key"
  type        = string
  default     = "/Users/zhangyanll/monash/FIT5225/CloudEco/key/oracle_k8s.pub"
}
