output "vpc_id" {
  value = aws_vpc.Bakur.id
}

output "vpc_cidr" {
  value = aws_vpc.Bakur.cidr_block
}
output "security_group_id" {
  value = aws_security_group.Bakur.id
}

output "public_subnets_id" {
  value = aws_subnet.public_subnets[*].id
}