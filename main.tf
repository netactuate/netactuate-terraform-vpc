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
  ip_version  = 4
  direction   = "inbound"
  protocol    = "TCP"
  port_start  = 80
  port_end    = 80
  network     = "0.0.0.0/0"
  description = "Allow inbound HTTP"
}

resource "netactuate_vpc_gateway_firewall_rule" "allow_ssh" {
  vpc_id      = netactuate_vpc.main.vpc_id
  ip_version  = 4
  direction   = "inbound"
  protocol    = "TCP"
  port_start  = 22
  port_end    = 22
  network     = "0.0.0.0/0"
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
  vpc_id               = netactuate_vpc.main.vpc_id
  ip_version           = 4
  protocol             = "TCP"
  match_port_start     = 8080
  match_port_end       = 8080
  translation_address  = "192.168.16.10"
  translation_port_start = 80
  translation_port_end   = 80
  description          = "Forward port 8080 to internal web server"
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
#   network_loadbalancer_id = netactuate_vpc.main.network_loadbalancer_id
#   name                    = "${var.vpc_label}-nlb"
#   description             = "Network load balancer for VPC"
#   ip_version              = 4
#   algorithm               = "round_robin"
#   match_address           = netactuate_vpc.main.bastion_ipv4
#
#   health_check {
#     enabled  = true
#     method   = "tcp"
#     interval = 10
#     retries  = 3
#     delay    = 5
#     timeout  = 5
#   }
#
#   rule {
#     protocol      = "tcp"
#     port_match    = 80
#     port_internal = 80
#   }
#
#   backend {
#     name             = "web-1"
#     internal_address = "192.168.16.10"
#   }
#
#   backend {
#     name             = "web-2"
#     internal_address = "192.168.16.11"
#   }
# }
#
# # --- SSL Certificate ---
# resource "netactuate_ssl_certificate" "main" {
#   name        = "${var.vpc_label}-cert"
#   certificate = file("certs/cert.pem")
#   private_key = file("certs/key.pem")
# }
#
# # --- HTTP Load Balancer ---
# resource "netactuate_http_loadbalancer_group" "hlb" {
#   http_loadbalancer_id = netactuate_vpc.main.http_loadbalancer_id
#   name                 = "${var.vpc_label}-hlb"
#   description          = "HTTP load balancer for VPC"
#   algorithm            = "round_robin"
#   internal_port        = 80
#   match_address        = netactuate_vpc.main.bastion_ipv4
#   match_ports          = "80+443"
#
#   rule {
#     match_domain           = var.hostname
#     match_path             = "/"
#     ssl_enabled            = true
#     ssl_certificate_id     = netactuate_ssl_certificate.main.ssl_certificate_id
#     https_redirect_enabled = true
#   }
#
#   backend {
#     name             = "web-1"
#     internal_address = "192.168.16.10"
#   }
#
#   backend {
#     name             = "web-2"
#     internal_address = "192.168.16.11"
#   }
# }
#
# # --- Backend Template ---
# resource "netactuate_vpc_backend_template" "web" {
#   vpc_id      = netactuate_vpc.main.vpc_id
#   name        = "${var.vpc_label}-backend-template"
#   description = "Backend template for web servers"
#
#   backend_host {
#     name    = "web-1"
#     address = "192.168.16.10"
#   }
#
#   backend_host {
#     name    = "web-2"
#     address = "192.168.16.11"
#   }
# }
