output "openshift_master_public_hostname" {
  value = "${local.public_admin_hostname}"
}
output "openshift_subdomain" {
  value = "${local.public_subdomain}"
}
output "bastion_hostnames" {
  value = ["${aws_instance.bastion.*.public_dns}"]
}
