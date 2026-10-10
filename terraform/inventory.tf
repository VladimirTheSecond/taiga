# Generates the Ansible inventory from Terraform outputs, so no IP is copied by hand.
# ansible_host is the IP, not the FQDN: right after apply the new A record may not
# have reached every resolver yet, but the IP works immediately.
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory/hosts.ini"
  file_permission = "0644"
  content = templatefile("${path.module}/templates/hosts.ini.tftpl", {
    host         = aws_eip.taiga.public_ip
    taiga_domain = local.taiga_fqdn
  })
}
