output "vpc_id" {
  description = "ID of the created VPC"
  value       = netactuate_vpc.main.vpc_id
}

output "vpc_status" {
  description = "Current status of the VPC"
  value       = netactuate_vpc.main.status
}

output "bastion_ipv4" {
  description = "Public IPv4 address of the VPC bastion/gateway"
  value       = netactuate_vpc.main.bastion_ipv4
}

output "bastion_ipv6" {
  description = "Public IPv6 address of the VPC bastion/gateway"
  value       = netactuate_vpc.main.bastion_ipv6
}

output "floating_ipv4" {
  description = "Floating IPv4 address attached to the VPC gateway"
  value       = netactuate_vpc_floating_ip.main.address
}

output "vm_id" {
  description = "ID of the VM deployed inside the VPC"
  value       = netactuate_server.vpc_vm.id
}

output "vm_private_ip" {
  description = "Private IP of the VM inside the VPC (from vpc_reserved_network)"
  value       = netactuate_server.vpc_vm.vpc_reserved_network
}

output "network_lb_id" {
  description = "ID of the network load balancer (empty until LB resources are uncommented)"
  value       = netactuate_vpc.main.network_loadbalancer_id
}

output "http_lb_id" {
  description = "ID of the HTTP load balancer (empty until LB resources are uncommented)"
  value       = netactuate_vpc.main.http_loadbalancer_id
}
