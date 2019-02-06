output "openshift master" {
  value = "${local.admin_hostname}"
}
output "openshift subdomain" {
  value = "${local.public_subdomain}"
}
output "bastion hostnames" {
  value = ["${aws_instance.bastion.*.public_dns}"]
}
