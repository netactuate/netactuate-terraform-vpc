variable "api_key" {
  description = "NetActuate API key (from portal.netactuate.com/account/api)"
  type        = string
  sensitive   = true
}

variable "contract_id" {
  description = "NetActuate billing contract ID"
  type        = string
}

variable "location" {
  description = "PoP location code for the VPC (e.g., \"LAX\", \"FRA\", \"SIN\")"
  type        = string
  default     = "LAX"
}

variable "plan" {
  description = "VM plan for servers inside the VPC (e.g., \"VR1x1x25\")"
  type        = string
  default     = "VR1x1x25"
}

variable "hostname" {
  description = "Hostname for the VM deployed inside the VPC"
  type        = string
  default     = "vpc-vm.example.com"
}

variable "ssh_key_id" {
  description = "SSH key ID from NetActuate portal to deploy on the VM"
  type        = number
}

variable "vpc_label" {
  description = "Label for the VPC"
  type        = string
  default     = "my-vpc"
}

variable "network_cidr" {
  description = "IPv4 CIDR for the VPC private network"
  type        = string
  default     = "192.168.16.0/20"
}
