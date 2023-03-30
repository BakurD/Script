provider "aws" {
  
}

resource "aws_vpc" "Bakur" {
  cidr_block = var.vpc_cidr
  enable_dns_hostnames = true
  tags = {
    Name = "IAC my VPC"
  }
}
resource "aws_internet_gateway" "Bakur" {
  vpc_id = aws_vpc.Bakur.id
  tags = {
    Name = "Bakur"
  }
}

# #Adjustments for s3 remote states, untags after create project
# resource "aws_s3_bucket" "tfstate" {
#   bucket = "bakur-tfstate-bucket"
#   versioning {
#     enabled = true
#   }
#   lifecycle {
#     prevent_destroy = true
#   }
#   server_side_encryption_configuration {
#     rule {
#       apply_server_side_encryption_by_default {
#         sse_algorithm = "AES256"
#       }
#     }
#   }
# }
# resource "aws_dynamodb_table" "terraform_locks" {
#   name           = "terraform-state-locking"
#   billing_mode   = "PAY_PER_REQUEST"
#   hash_key       = "LockID"

#   attribute {
#     name = "LockID"
#     type = "S"
#   }
# }


#Create Security Group
resource "aws_security_group" "Bakur" {
  name   = "Dynamic Security Group"
  vpc_id = aws_vpc.Bakur.id
  dynamic "ingress" {
    for_each = ["80", "443", "22", "943", "1194"] #443, 22, 943, 1194 - for vpn
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "Dynamic SecurityGroup"
    Owner = "Maxim Bakurevych"
  }
}

#Create Pubic Subnets
resource "aws_subnet" "public_subnets" {
  count = length(var.public_subnet_cidr)
  vpc_id = aws_vpc.Bakur.id
  cidr_block = element(var.public_subnet_cidr, count.index)
  availability_zone = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet ${count.index + 1}"
  }
}

#Route tables Public Subnets

resource "aws_route_table" "public_subnets" {
  vpc_id = aws_vpc.Bakur.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.Bakur.id
  }
  tags = {
    Name = "Public_Subnets"
  }
}

resource "aws_route_table_association" "public_routes" {
  count = length(aws_subnet.public_subnets[*].id)
  route_table_id = aws_route_table.public_subnets.id
  subnet_id = element(aws_subnet.public_subnets[*].id, count.index)
}

#Create Privete Subnets
resource "aws_subnet" "private_subnet_1" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.private_subnet_1_cidr
  vpc_id = aws_vpc.Bakur.id
  map_public_ip_on_launch = false
  tags = {
    Name = "Private Subnet 1"
  }
}
resource "aws_subnet" "private_subnet_2" {
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = var.private_subnet_2_cidr
  vpc_id = aws_vpc.Bakur.id
  map_public_ip_on_launch = false
  tags = {
    Name = "Private Subnet 2"
  }
}

resource "aws_eip" "NAT-1" {
  vpc = true
 }

resource "aws_eip" "NAT-2" {
  vpc = true
}


resource "aws_nat_gateway" "NAT_1" {                       #HZ1)
  allocation_id = aws_eip.NAT-1.id
  subnet_id =  element(aws_subnet.public_subnets.*.id, 0)
  tags = {
    Name = "NAT-1"
  }
}
resource "aws_nat_gateway" "NAT_2" {                     #HZ2)
  allocation_id = aws_eip.NAT-2.id
  subnet_id =  element(aws_subnet.public_subnets.*.id, 1)
  tags = {
    Name = "NAT-2"
  }
}

resource "aws_route_table" "private_subnet_1" {
  vpc_id = aws_vpc.Bakur.id
  tags = {
    Name = "Public_Subnets-1"
  }
}

resource "aws_route_table" "private_subnet_2" {
  vpc_id = aws_vpc.Bakur.id
  tags = {
    Name = "Public_Subnets-2"
  }
}

resource "aws_route" "private_nat_gateway_1" {
  route_table_id         = aws_route_table.private_subnet_1.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.NAT_1.id
}

resource "aws_route" "private_nat_gateway_2" {
  route_table_id         = aws_route_table.private_subnet_2.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.NAT_2.id
}

resource "aws_route" "public_internet_gateway_1" {
  route_table_id         = aws_route_table.public_subnets.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.Bakur.id
}

resource "aws_route" "public_internet_gateway_2" {
  route_table_id         = aws_route_table.public_subnets.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.Bakur.id
}

resource "aws_route_table_association" "private_1" {
  subnet_id      = aws_subnet.private_subnet_1.id
  route_table_id = aws_route_table.private_subnet_1.id
}
resource "aws_route_table_association" "private_2" {
  subnet_id      = aws_subnet.private_subnet_2.id
  route_table_id = aws_route_table.private_subnet_2.id
}
#DataBase Subnets, need adjustments
resource "aws_subnet" "DB-Subnet_1" {
  availability_zone = data.aws_availability_zones.available.names[0]
  cidr_block = var.db_subnet_1
  vpc_id = aws_vpc.Bakur.id
  map_public_ip_on_launch = false
  tags = {
    Name = "DB Subnet 1"
  }
}
resource "aws_subnet" "DB-Subnet_2" {
  availability_zone = data.aws_availability_zones.available.names[1]
  cidr_block = var.db_subnet_2
  vpc_id = aws_vpc.Bakur.id
  map_public_ip_on_launch = false
  tags = {
    Name = "DB Subnet 2"
  }
}

resource "aws_route_table" "db_subnet_1" {
  vpc_id = aws_vpc.Bakur.id
  tags = {
    Name = "DB_Subnets 1"
  }
}

resource "aws_route_table" "db_subnet_2" {
  vpc_id = aws_vpc.Bakur.id
  tags = {
    Name = "DB_Subnets 2"
  }
}

resource "aws_route_table_association" "db_1" {
  subnet_id      = aws_subnet.DB-Subnet_1.id
  route_table_id = aws_route_table.db_subnet_1.id
}
resource "aws_route_table_association" "db_2" {
  subnet_id      = aws_subnet.DB-Subnet_2.id
  route_table_id = aws_route_table.db_subnet_2.id
}



#Create 1 instance per region
resource "aws_launch_configuration" "web" {
  name_prefix     = "WebServer-Highly-Available-LC-"
  image_id        = data.aws_ami.latest_ubuntu.id
  instance_type   = "t2.micro"
  security_groups = [aws_security_group.Bakur.id]
  associate_public_ip_address = true
  user_data = <<EOF
#!/bin/bash
sudo apt update -y
sudo apt install apache2 -y
echo "<html><body bgcolor=white><center><h2><p><front color=red>Bootstraping one love</h2></center></html>" > /var/www/html/index.html
sudo service apache2 start
chkconfig apache2 on
echo "UserData excuted on $(date)" >> /var/www/html/log.txt
echo "-----FINISH-----"
EOF

  metadata_options {
    http_endpoint               = "enabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "optional"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "web" {
  name                 = "ASG-${aws_launch_configuration.web.name}"
  launch_configuration = aws_launch_configuration.web.name
  min_size             = 4
  max_size             = 4
  min_elb_capacity     = 4
  vpc_zone_identifier  = [element(aws_subnet.public_subnets.*.id, 1), element(aws_subnet.public_subnets.*.id, 0)]#, aws_subnet.private_subnet-1.id, aws_subnet.private_subnet-2.id, aws_subnet.DB-Subnet-1.id, aws_subnet.DB-Subnet-1.id]

  dynamic "tag" {
    for_each = {
      Name   = "WebServer in ASG"
      Owner  = "Maxim Bakurevych"
      TAGKEY = "TAGVALUE"
    }
    content {
      key                 = tag.key
      value               = tag.value
      propagate_at_launch = true
    }
  }

  lifecycle {
    create_before_destroy = true
  }
  depends_on = [
    aws_launch_configuration.web
  ]
}

