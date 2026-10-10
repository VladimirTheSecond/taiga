# The zone itself lives in terraform/bootstrap/ and survives `make down`.
# This stack only looks it up and adds a record that lives and dies with the instance.
data "aws_route53_zone" "main" {
  name = var.domain_name
}

locals {
  taiga_fqdn = "${var.taiga_subdomain}.${var.domain_name}"
}

resource "aws_route53_record" "taiga" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.taiga_fqdn
  type    = "A"
  ttl     = 60 # Short TTL: the EIP changes on every rebuild, resolvers must not cache the old one for long
  records = [aws_eip.taiga.public_ip]
}
