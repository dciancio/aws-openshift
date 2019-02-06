# Specify the provider and access details
provider "aws" {
  region = "${var.aws_region}"
}
# Declare the data source
data "aws_availability_zones" "available" {}
data "template_file" "sysprep-bastion" {
  template = "${file("./helper_scripts/sysprep-bastion.sh")}"
  vars {
    rhuser = "${var.rhuser}"
    rhpass = "${var.rhpass}"
    rhpool = "${var.rhpool}"
    ocp_version = "${var.ocp_version}"
    ansible_version = "${var.ansible_version}"
  }
}
data "template_file" "sysprep-openshift" {
  template = "${file("./helper_scripts/sysprep-openshift.sh")}"
  vars {
    rhuser = "${var.rhuser}"
    rhpass = "${var.rhpass}"
    rhpool = "${var.rhpool}"
    ocp_version = "${var.ocp_version}"
    ansible_version = "${var.ansible_version}"
  }
}
