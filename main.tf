terraform {
  required_providers {
    netactuate = {
      source  = "netactuate/netactuate"
      version = ">= 0.2.5"
    }
  }
  required_version = ">= 1.0"
}

provider "netactuate" {
  api_key = var.api_key
}

# ---------------------------------------------------------------------------
# VPC
# ---------------------------------------------------------------------------

resource "netactuate_vpc" "main" {
  label              = var.vpc_label
  description        = "VPC managed by Terraform"
  location           = var.location
  network_ipv4       = var.network_cidr
  nameservers_ipv4   = ["1.1.1.1", "8.8.8.8"]
  enable_default_snat = true
}

# ---------------------------------------------------------------------------
# Firewall rules — allow inbound traffic through VPC gateway
# ---------------------------------------------------------------------------

resource "netactuate_vpc_gateway_firewall_rule" "allow_http" {
  vpc_id      = netactuate_vpc.main.vpc_id
  direction   = "inbound"
  protocol    = "tcp"
  port        = 80
  source_cidr = "0.0.0.0/0"
  action      = "allow"
  description = "Allow inbound HTTP"
}

resource "netactuate_vpc_gateway_firewall_rule" "allow_ssh" {
  vpc_id      = netactuate_vpc.main.vpc_id
  direction   = "inbound"
  protocol    = "tcp"
  port        = 22
  source_cidr = "0.0.0.0/0"
  action      = "allow"
  description = "Allow inbound SSH"
}

# ---------------------------------------------------------------------------
# Floating IP — public IPv4 attached to VPC gateway
# ---------------------------------------------------------------------------

resource "netactuate_vpc_floating_ip" "main" {
  vpc_id  = netactuate_vpc.main.vpc_id
  version = 4
  ptr     = var.hostname
}

# ---------------------------------------------------------------------------
# DNAT — forward external port 8080 to internal VM on port 80
# ---------------------------------------------------------------------------

resource "netactuate_vpc_gateway_dnat_rule" "web_forward" {
  vpc_id           = netactuate_vpc.main.vpc_id
  external_port    = 8080
  internal_address = "192.168.16.10"
  internal_port    = 80
  protocol         = "tcp"
  description      = "Forward port 8080 to internal web server"
}

# ---------------------------------------------------------------------------
# VM inside the VPC
# ---------------------------------------------------------------------------

resource "netactuate_server" "vpc_vm" {
  hostname                    = var.hostname
  plan                        = var.plan
  location                    = var.location
  image                       = "Ubuntu 24.04 LTS (20240423)"
  ssh_key_id                  = var.ssh_key_id
  package_billing             = "usage"
  package_billing_contract_id = var.contract_id
  vpc_id                      = netactuate_vpc.main.vpc_id
}

# ===========================================================================
# Advanced: Load Balancing
# ===========================================================================
# Uncomment to enable load balancing. These resources create network and HTTP
# load balancers attached to the VPC, along with SSL certificates and backend
# templates.
#
# # --- Network Load Balancer ---
# resource "netactuate_network_loadbalancer_group" "nlb" {
#   vpc_id      = netactuate_vpc.main.vpc_id
#   label       = "${var.vpc_label}-nlb"
#   description = "Network load balancer for VPC"
#
#   health_check {
#     protocol = "tcp"
#     port     = 80
#     interval = 10
#     timeout  = 5
#   }
#
#   rule {
#     listen_port  = 80
#     target_port  = 80
#     protocol     = "tcp"
#   }
#
#   backend {
#     address = "192.168.16.10"
#     port    = 80
#   }
#
#   backend {
#     address = "192.168.16.11"
#     port    = 80
#   }
# }
#
# # --- HTTP Load Balancer ---
# resource "netactuate_ssl_certificate" "main" {
#   name             = "${var.vpc_label}-cert"
#   certificate_body = file("certs/cert.pem")
#   private_key      = file("certs/key.pem")
#   certificate_chain = file("certs/chain.pem")
# }
#
# resource "netactuate_http_loadbalancer_group" "hlb" {
#   vpc_id      = netactuate_vpc.main.vpc_id
#   label       = "${var.vpc_label}-hlb"
#   description = "HTTP load balancer for VPC"
#
#   ssl_certificate_id = netactuate_ssl_certificate.main.id
#
#   domain_rule {
#     domain = var.hostname
#     path   = "/"
#   }
#
#   backend {
#     address = "192.168.16.10"
#     port    = 80
#   }
#
#   backend {
#     address = "192.168.16.11"
#     port    = 80
#   }
# }
#
# # --- Backend Template ---
# resource "netactuate_vpc_backend_template" "web" {
#   vpc_id      = netactuate_vpc.main.vpc_id
#   label       = "${var.vpc_label}-backend-template"
#   port        = 80
#   protocol    = "tcp"
#   description = "Backend template for web servers"
# }
