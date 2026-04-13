# netactuate-terraform-vpc

Terraform module for deploying a VPC on NetActuate's global edge network. Creates a private
network with SNAT, gateway firewall rules, a floating IP, DNAT port forwarding, and a VM
inside the VPC -- all with a single `terraform apply`.

## What This Deploys

- **VPC** with a /20 private network and default SNAT for outbound internet access
- **Firewall rules** allowing inbound HTTP (port 80) and SSH (port 22) through the gateway
- **Floating IP** (IPv4) attached to the VPC gateway with reverse DNS (PTR)
- **DNAT rule** forwarding external port 8080 to an internal VM on port 80
- **VM** deployed inside the VPC with a private IP from the VPC network
- (Optional) **Network and HTTP load balancers** -- commented out, ready to enable

## Prerequisites

- **Terraform 1.0+** or **OpenTofu**
- A NetActuate API key ([portal.netactuate.com/account/api](https://portal.netactuate.com/account/api))
- An SSH key ID from the NetActuate portal

### Install Terraform

**macOS:**
```bash
brew install terraform
```

**Linux:**
```bash
# Using tfenv
git clone https://github.com/tfutils/tfenv.git ~/.tfenv
echo 'export PATH="$HOME/.tfenv/bin:$PATH"' >> ~/.bashrc
tfenv install latest
tfenv use latest
```

Or download the binary directly from [terraform.io/downloads](https://www.terraform.io/downloads).

**Windows:**
```powershell
winget install Hashicorp.Terraform
```

Or use WSL2 with the Linux instructions above.

## Configuration

### Step 1: Copy the example tfvars

```bash
cp terraform.tfvars.example terraform.tfvars
```

**Never commit `terraform.tfvars`** -- it contains your API key and is gitignored.

### Step 2: Fill in your values

| Variable | Type | Description | Example |
|----------|------|-------------|---------|
| `api_key` | string | NetActuate API key (sensitive) | `"abc123..."` |
| `contract_id` | string | Billing contract ID | `"12345"` |
| `location` | string | PoP location code (default: LAX) | `"LAX"` |
| `plan` | string | VM sizing plan (default: VR1x1x25) | `"VR1x1x25"` |
| `hostname` | string | VM hostname (default: vpc-vm.example.com) | `"web.example.com"` |
| `ssh_key_id` | number | SSH key ID from portal | `12345` |
| `vpc_label` | string | Label for the VPC (default: my-vpc) | `"prod-vpc"` |
| `network_cidr` | string | VPC private network CIDR (default: 192.168.16.0/20) | `"192.168.16.0/20"` |

## Usage

```bash
# Initialize providers
terraform init

# Preview what will be created
terraform plan

# Create the VPC and all resources
terraform apply

# View VPC bastion IP (use this for SSH access)
terraform output bastion_ipv4

# View the VM's private IP inside the VPC
terraform output vm_private_ip
```

## Outputs

| Output | Description |
|--------|-------------|
| `vpc_id` | ID of the created VPC |
| `vpc_status` | Current status of the VPC |
| `bastion_ipv4` | Public IPv4 of the VPC gateway -- use this for SSH access |
| `bastion_ipv6` | Public IPv6 of the VPC gateway |
| `floating_ipv4` | Floating IP attached to the gateway |
| `vm_id` | ID of the VM inside the VPC |
| `vm_private_ip` | Private IP assigned to the VM (from `vpc_reserved_network`) |
| `network_lb_id` | Network load balancer ID (populated when VPC has an NLB) |
| `http_lb_id` | HTTP load balancer ID (populated when VPC has an HLB) |

### Accessing the VM

The VM has a private IP only. To reach it, SSH through the bastion gateway:

```bash
ssh -J root@$(terraform output -raw bastion_ipv4) root@$(terraform output -raw vm_private_ip)
```

The DNAT rule forwards `bastion_ipv4:8080` to the VM's port 80, so you can also access
web services at `http://<bastion_ipv4>:8080`.

## Advanced: Load Balancing

The `main.tf` file includes commented-out resources for network and HTTP load balancers.
To enable them:

1. Uncomment the load balancer resource blocks in `main.tf`
2. For HTTP load balancers, place your SSL certificate files in a `certs/` directory
3. Adjust backend addresses to match your VPC server IPs
4. Run `terraform apply`

Available load balancer resources:

- `netactuate_network_loadbalancer_group` -- Layer 4 TCP/UDP load balancing with health checks
- `netactuate_http_loadbalancer_group` -- Layer 7 HTTP/HTTPS load balancing with domain rules and SSL
- `netactuate_ssl_certificate` -- SSL certificate management for HTTPS load balancers
- `netactuate_vpc_backend_template` -- Reusable backend configuration template

## Teardown

```bash
terraform destroy
```

This destroys the VPC, all firewall rules, floating IPs, DNAT rules, and the VM.

## AI-Assisted (Claude Code / Cursor / Copilot)

```
Deploy a NetActuate VPC with Terraform:

- API Key: <YOUR_API_KEY>
- Contract ID: <YOUR_CONTRACT_ID>
- Location: LAX
- SSH Key ID: <YOUR_SSH_KEY_ID>
- Plan: VR1x1x25
- VPC Label: my-vpc

Please:
1. Copy terraform.tfvars.example to terraform.tfvars and fill in values
2. Run terraform init && terraform apply
3. Show me the bastion_ipv4 and vm_private_ip outputs
4. Show me how to SSH into the VM through the bastion
```

## Need Help?

- NetActuate support: support@netactuate.com
- [NetActuate API Documentation](https://www.netactuate.com/docs/)
- [Terraform NetActuate Provider](https://registry.terraform.io/providers/netactuate/netactuate/latest)
- [NetActuate Portal](https://portal.netactuate.com)
