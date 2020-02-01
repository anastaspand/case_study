variable "resource_group_name" {
  description = "Resource group name that will contain all resources"
}

variable "location" {
  description = "The Azure region for the resource provisioning"
}

variable "vnet_cidr" {
  description = "CIDR block for Virtual Network"
}

variable "subnet_cidr" {
  description = "CIDR block for Subnet within a Virtual Network"
}

variable "vm_username" {
  description = "Enter admin username to SSH into VM"
}

variable "ssh_key" {
  description = "Enter ssh key to access VM"
}

variable "jenkins_dnslabel" {
  description = "Jenkins domain label"
}

variable "environment" {
  description = "Environment Tag"
}