# SSH is open only to the public IP of whoever runs `terraform apply`.
# The IP is detected on every run, so a new network (home, cafe, office) just changes the rule.
data "http" "my_ip" {
  url = "https://checkip.amazonaws.com"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Could not detect the public IP. Set allowed_ssh_cidr manually."
    }
  }
}

locals {
  ssh_cidr = var.allowed_ssh_cidr != "" ? var.allowed_ssh_cidr : "${chomp(data.http.my_ip.response_body)}/32"
}
