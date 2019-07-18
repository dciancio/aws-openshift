output "openshift_public_api_hostname" {
  value = local.public_api_hostname
}

output "openshift_subdomain" {
  value = local.public_subdomain
}

output "bastion_hostnames" {
  value = [aws_instance.bastion.*.public_dns]
}

