#####################################################
#    DATA SOURCE                                    #
#####################################################
data "aws_ami" "server_ami" {
  most_recent = true
  owners      = ["099720109477"]
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
  }
}

#####################################################
#    Security Group                                 #
#####################################################
# security group
resource "aws_security_group" "galaxy_demo_sg" {
  depends_on  = [aws_vpc.galaxy_demo_vpc]
  name        = "public_sg"
  description = "Security group for public instance"
  vpc_id      = aws_vpc.galaxy_demo_vpc.id

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    "Name" = "galaxy-demo-public-sg-${random_id.random.dec}"
  }
}

# security group rule
resource "aws_security_group_rule" "ingress_all" {
  depends_on        = [aws_security_group.galaxy_demo_sg]
  type              = "ingress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = [var.access_ip, var.cloud9_ip]
  security_group_id = aws_security_group.galaxy_demo_sg.id
}

resource "aws_security_group_rule" "egress_all" {
  depends_on        = [aws_security_group.galaxy_demo_sg]
  type              = "egress"
  from_port         = 0
  to_port           = 65535
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.galaxy_demo_sg.id
}

#####################################################
#              KEY PAIR                             #
#####################################################
resource "aws_key_pair" "galaxy_demo_auth" {
  depends_on = [var.public_key_path]
  key_name   = var.key_name
  public_key = file(var.public_key_path)

}

#####################################################
#                    EC2                            #
#####################################################
resource "aws_instance" "galaxy_demo_main" {
  depends_on    = [aws_vpc.galaxy_demo_vpc, aws_key_pair.galaxy_demo_auth, aws_security_group.galaxy_demo_sg, aws_subnet.galaxy_demo_public_subnet]
  count         = var.main_instance_count
  instance_type = var.main_instance_type
  ami           = data.aws_ami.server_ami.id
  key_name      = aws_key_pair.galaxy_demo_auth.id

  vpc_security_group_ids = [aws_security_group.galaxy_demo_sg.id]
  subnet_id              = aws_subnet.galaxy_demo_public_subnet[count.index].id

  root_block_device {
    volume_size = var.main_vol_size
  }

  tags = {
    "Name" = "galaxy_demo_main-${random_id.galaxy_demo_node_id[count.index].dec}"
  }

  provisioner "local-exec" {
    command = "printf '\n${self.public_ip}' >> aws_hosts && aws ec2 wait instance-status-ok --instance-ids ${self.id} --region ${var.aws_region}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "sed -i '/^[0-9]/d' aws_hosts"
  }
}

#####################################################
#                 MISC                              #
#####################################################
resource "random_id" "galaxy_demo_node_id" {
  byte_length = 2
  count       = var.main_instance_count
}

resource "null_resource" "app_install" {
  depends_on = [aws_instance.galaxy_demo_main]
  provisioner "local-exec" {
    command = "ansible-playbook -i aws_hosts --key-file /home/ubuntu/.ssh/demo-devops-cloud-TAJ playbooks/main-playbook.yml"
  }
}

output "instance_ips" {
  value = { for i in aws_instance.galaxy_demo_main[*] : i.tags.Name => "${i.public_ip}:3000" }
}