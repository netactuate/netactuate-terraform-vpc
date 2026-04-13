# netactuate-terraform-vpc -- AI Provisioning Context

Terraform module for deploying a VPC on NetActuate. Creates a private network with SNAT,
firewall rules, floating IP, DNAT port forwarding, and a VM inside the VPC. Optionally
supports network and HTTP load balancers.

Give me: API key + contract ID + location + SSH key ID + plan --> VPC deployed with
bastion access and private VM.

## Required Inputs

| Input | Source | Example |
|-------|--------|---------|
| API key | portal.netactuate.com/account/api | `"abc123..."` |
| Contract ID | Portal API page | `"12345"` |
| Location | Customer choice | `"LAX"` |
| SSH key ID | Portal SSH keys page | `12345` |
| Plan | Customer choice | `"VR1x1x25"` |

## What to Do

1. Copy `terraform.tfvars.example` to `terraform.tfvars`
2. Fill in values (never commit `terraform.tfvars`)
3. Run:
   ```bash
   terraform init
   terraform apply
   ```
4. Get the bastion IP and VM private IP:
   ```bash
   terraform output bastion_ipv4
   terraform output vm_private_ip
   ```
5. SSH into the VM through the bastion:
   ```bash
   ssh -J root@$(terraform output -raw bastion_ipv4) root@$(terraform output -raw vm_private_ip)
   ```

## VPC Architecture

The VPC creates:
- A private /20 network (192.168.16.0/20 by default)
- A bastion/gateway with public IPv4 and IPv6
- Default SNAT so VPC VMs can reach the internet
- Firewall rules controlling inbound traffic
- Floating IP for stable public addressing
- DNAT rules for port forwarding to internal VMs

VMs inside the VPC get a private IP from `vpc_reserved_network` -- they have no public IPs.
All external access goes through the bastion gateway.

## Enabling Load Balancers

The `main.tf` file includes commented-out load balancer resources. To enable:

1. Uncomment the resource blocks at the bottom of `main.tf`
2. Place SSL certs in `certs/` for HTTP load balancers
3. Adjust backend addresses to match your server IPs
4. Run `terraform apply`

## Teardown

```bash
terraform destroy
```

## Common Errors

| Error | Fix |
|-------|-----|
| Provider not found | Run `terraform init` |
| API key invalid | Check `terraform.tfvars` -- key must be whitelisted on portal |
| Location not found | Check PoP code against portal API page |
| SSH key ID not found | Verify the key ID exists on portal.netactuate.com/account/ssh |
| VPC network conflict | Change `network_cidr` to a non-overlapping range |
| DNAT target unreachable | Ensure the internal address is within the VPC network CIDR |
