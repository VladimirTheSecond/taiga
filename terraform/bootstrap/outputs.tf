output "state_bucket" {
  description = "S3 bucket for the main stack state (used in its backend block)"
  value       = aws_s3_bucket.tfstate.id
}

output "zone_id" {
  description = "Route 53 hosted zone ID"
  value       = aws_route53_zone.main.zone_id
}

output "name_servers" {
  description = "Name servers that must be set at the registrar"
  value       = aws_route53_zone.main.name_servers
}
