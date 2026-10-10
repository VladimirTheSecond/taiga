# The zone was created by hand with the AWS CLI on 2026-10-09 and delegated at INWX.
# The import block brings it under Terraform without recreating it.
# A recreated zone would get new name servers and break the delegation at the registry.
import {
  to = aws_route53_zone.main
  id = "Z05298261IAJVNBKNGXS5"
}

resource "aws_route53_zone" "main" {
  name    = var.domain_name
  comment = "Persistent zone, delegated at INWX. Never destroy."

  lifecycle {
    prevent_destroy = true
  }
}
