variable "aws_region" {
  description = "AWS region for all resources"
  type        = string
  default     = "eu-central-1" # Frankfurt
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.medium" # 2 CPU 4 Gb RAM
}

variable "root_volume_size" {
  description = "Size of the root EBS volume in GB"
  type        = number
  default     = 30 # 30 Gb Disk space
}

variable "ssh_public_key_path" {
  description = "Path to the SSH public key on your local machine"
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "allowed_ssh_cidr" {
  description = "CIDR block allowed to SSH into the instance"
  type        = string
  default     = "0.0.0.0/0" # Will change this later, so far any IP address is able to connect to our new instance
}
