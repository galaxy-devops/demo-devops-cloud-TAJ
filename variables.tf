variable "aws_region" {
  type = string
}

variable "vpc_cidr" {
  type    = string
  default = "10.123.0.0/16"
}

variable "public_cidrs" {
  type    = list(string)
  default = ["10.123.1.0/24", "10.123.3.0/24"]
}

variable "private_cidrs" {
  type    = list(string)
  default = ["10.123.2.0/24", "10.123.4.0/24"]
}

variable "access_ip" {
  type    = string
  default = "0.0.0.0/0"
}

variable "main_instance_type" {
  type    = string
  default = "t2.micro"
}

variable "main_vol_size" {
  type    = number
  default = 8
}

variable "main_instance_count" {
  type    = number
  default = 1
}

variable "key_name" {
  type = string
}

variable "public_key_path" {
  type = string
}

# Cloud9 host EIP
variable "cloud9_ip" {
  type    = string
  default = "54.86.16.204/32"
}

variable "cidr_extension_number" {
  type    = number
  default = 8
}