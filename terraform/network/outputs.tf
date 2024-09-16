# Output the VPC ID
output "vpc_id" {
  value       = aws_vpc.main_vpc.id
  description = "The ID of the VPC"
}

# Output the Public Subnet IDs (for each AZ)
output "public_subnet_ids" {
  value       = aws_subnet.public_subnet[*].id
  description = "The IDs of the public subnets"
}

# Output the Private Subnet IDs (for each AZ)
output "private_subnet_ids" {
  value       = aws_subnet.private_subnet[*].id
  description = "The IDs of the private subnets"
}

# Output the Availability Zones for the Subnets
output "availability_zones" {
  value       = data.aws_availability_zones.available.names
  description = "The availability zones used for subnets"
}

# Output the Internet Gateway ID
output "internet_gateway_id" {
  value       = aws_internet_gateway.main_igw.id
  description = "The ID of the Internet Gateway"
}

# Output the NAT Gateway IDs
output "nat_gateway_ids" {
  value       = aws_nat_gateway.nat_gateway[*].id
  description = "The ID of the NAT Gateways"
}

# Output the Public Route Table IDs
output "public_route_table_ids" {
  value       = aws_route_table.public_rt[*].id
  description = "The ID of the public route tables"
}

# Output the Private Route Table IDs
output "private_route_table_ids" {
  value       = aws_route_table.private_rt[*].id
  description = "The ID of the private route tables"
}

# Output the Elastic IP for the NAT Gateways
output "nat_eip_ids" {
  value       = aws_eip.nat_eip[*].id
  description = "The ID of the Elastic IPs for the NAT Gateways"
}

# ALB Security Group ID
output "alb_sg_ids" {
  value = {
    for env in local.environments : env => aws_security_group.alb_sg[env].id
  }
  description = "The ID of the security group for the ALB for each environment"
}

# ALB DNS name
output "alb_dns" {
  value = {
    for env in local.environments : env => aws_lb.app_lb[env].dns_name
  }
  description = "The DNS name of the ALB for each environment"
}

# Target Group A
output "target_group_arns" {
  value = {
    for env in local.environments : env => aws_lb_target_group.app_tg[env].arn
  }
  description = "The arn of the target group for each environment"
}