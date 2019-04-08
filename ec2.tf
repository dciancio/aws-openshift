resource "aws_instance" "bastion" {
  count           = "${var.bastion_count}"
  ami             = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type   = "${var.bastion_instance_type}"
  subnet_id       = "${element(aws_subnet.public.*.id, count.index)}"
  security_groups = ["${aws_security_group.sec_bastion.id}"]
  key_name        = "${var.keypair}"
  user_data       = "${data.template_file.sysprep-bastion.rendered}"
  iam_instance_profile = "${var.instancerole}"
  associate_public_ip_address = true
  tags = "${map(
    "Name", "${var.clustername}-bastion-${count.index}",
    "${local.clustertagkey}", "${local.clustertagvalue}"
    )}"
  volume_tags = "${map(
    "Name", "${var.clustername}-bastion-${count.index}",
    "${local.clustertagkey}", "${local.clustertagvalue}"
    )}"
  provisioner "file" {
    source      = "${path.cwd}/inventory/ansible-hosts"
    destination = "~/hosts"
    connection {
       type     = "ssh"
       user     = "ec2-user"
    }
  }
  depends_on = ["local_file.inventory"]
}
resource "aws_instance" "master" {
  count                = "${var.master_count}"
  ami                  = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type        = "${var.master_instance_type}"
  subnet_id            = "${element(aws_subnet.private.*.id, count.index)}"
  security_groups      = ["${aws_security_group.sec_openshift.id}"]
  key_name             = "${var.keypair}"
  user_data            = "${data.template_file.sysprep-openshift.rendered}"
  iam_instance_profile = "${var.instancerole}"
  tags = "${map(
    "Name", "${var.clustername}-master-${count.index}",
    "${local.clustertagkey}", "${local.clustertagvalue}"
    )}"
  volume_tags = "${map(
    "Name", "${var.clustername}-master-${count.index}",
    "${local.clustertagkey}", "${local.clustertagvalue}"
    )}"
  ebs_block_device {
    device_name = "/dev/xvdf"
    volume_type = "gp2"
    volume_size = 100
    delete_on_termination = true
  }
}
resource "aws_instance" "worker" {
  count                = "${var.worker_count}"
  ami                  = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type        = "${var.worker_instance_type}"
  subnet_id            = "${element(aws_subnet.private.*.id, count.index)}"
  security_groups      = ["${aws_security_group.sec_openshift.id}"]
  key_name             = "${var.keypair}"
  user_data            = "${data.template_file.sysprep-openshift.rendered}"
  iam_instance_profile = "${var.instancerole}"
  tags = "${map(
    "Name", "${var.clustername}-worker-${count.index}",
    "${local.clustertagkey}", "${local.clustertagvalue}"
    )}"
  volume_tags = "${map(
    "Name", "${var.clustername}-worker-${count.index}",
    "${local.clustertagkey}", "${local.clustertagvalue}"
    )}"
  ebs_block_device {
    device_name = "/dev/xvdf"
    volume_type = "gp2"
    volume_size = 100
    delete_on_termination = true
  }
}
resource "aws_instance" "infra" {
  count                = "${var.infra_count}"
  ami                  = "${lookup(var.aws_amis, var.aws_region)}"
  instance_type        = "${var.infra_instance_type}"
  subnet_id            = "${element(aws_subnet.private.*.id, count.index)}"
  security_groups      = ["${aws_security_group.sec_openshift.id}"]
  key_name             = "${var.keypair}"
  user_data            = "${data.template_file.sysprep-openshift.rendered}"
  iam_instance_profile = "${var.instancerole}"
  tags = "${map(
    "Name", "${var.clustername}-infra-${count.index}",
    "${local.clustertagkey}", "${local.clustertagvalue}"
    )}"
  volume_tags = "${map(
    "Name", "${var.clustername}-infra-${count.index}",
    "${local.clustertagkey}", "${local.clustertagvalue}"
    )}"
  ebs_block_device {
    device_name = "/dev/xvdf"
    volume_type = "gp2"
    volume_size = 100
    delete_on_termination = true
  }
}
