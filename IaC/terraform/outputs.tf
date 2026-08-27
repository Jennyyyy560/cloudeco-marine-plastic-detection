# Terraform Outputs - Prints VM IPs after terraform apply
# These IPs should be copied into ansible-k8s/k8s-hosts.ini

output "master_public_ip" {
  description = "Public IP of k8s-master — use this in k8s-hosts.ini [masters]"
  value       = google_compute_instance.k8s_master.network_interface[0].access_config[0].nat_ip
}

output "worker1_public_ip" {
  description = "Public IP of k8s-worker1 — use this in k8s-hosts.ini [workers]"
  value       = google_compute_instance.k8s_worker1.network_interface[0].access_config[0].nat_ip
}

output "worker2_public_ip" {
  description = "Public IP of k8s-worker2 — use this in k8s-hosts.ini [workers]"
  value       = google_compute_instance.k8s_worker2.network_interface[0].access_config[0].nat_ip
}

output "next_step" {
  description = "What to do after terraform apply"
  value       = "Copy the IPs above into ansible-k8s/k8s-hosts.ini, then run the Ansible playbooks in order."
}
