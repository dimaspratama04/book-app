variable "project_id" {
  description = "GCP project ID where resources are created."
  type        = string
}

variable "region" {
  description = "GCP region for regional resources."
  type        = string
  default     = "asia-southeast2"
}

variable "zone" {
  description = "GCP zone where the VM is provisioned."
  type        = string
  default     = "asia-southeast2-a"
}

variable "instance_name" {
  description = "Name of the compute instance."
  type        = string
  default     = "book-app-vm"
}

variable "machine_type" {
  description = "VM machine type. e2-medium = 2 vCPU, 4 GB memory."
  type        = string
  default     = "e2-medium"
}

variable "image" {
  description = "Boot disk image for the VM."
  type        = string
  default     = "ubuntu-os-cloud/ubuntu-2204-lts"
}

variable "disk_size_gb" {
  description = "Size of the boot disk in GB."
  type        = number
  default     = 20
}

variable "network" {
  description = "VPC network to attach the VM to."
  type        = string
  default     = "default"
}

variable "ssh_user" {
  description = "Username for SSH access."
  type        = string
  default     = "ubuntu"
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key added to the VM metadata."
  type        = string
  default     = "~/.ssh/id_rsa.pub"
}

# --- DNS ---

variable "dns_zone_name" {
  description = "Name of the Cloud DNS managed zone (resource name, no dots)."
  type        = string
  default     = "book-app-zone"
}

variable "dns_domain" {
  description = "DNS domain for the managed zone. Must end with a trailing dot, e.g. example.com."
  type        = string
}

variable "dns_record_name" {
  description = "Hostname (subdomain) to point at the VM, prepended to dns_domain. e.g. 'app'."
  type        = string
  default     = "app"
}

variable "dns_ttl" {
  description = "TTL in seconds for the DNS A record."
  type        = number
  default     = 300
}
