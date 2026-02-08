variable "pm_api_url" {
  type        = string
  description = "Proxmox API endpoint (e.g., https://host:8006/api2/json)"
}

variable "pm_api_token" {
  type        = string
  description = "Proxmox API token in the form 'USER@REALM!TOKEN=SECRET'"
  sensitive   = true
}

variable "pm_tls_insecure" {
  type        = bool
  description = "Allow insecure TLS (useful for self-signed certs in lab)"
  default     = true
}

variable "pve_node" {
  type        = string
  description = "Proxmox node name"
  default     = "pve"
}

variable "vm_name" {
  type        = string
  description = "Name of the Terraform-managed VM"
  default     = "tf-lab-utility-01"
}