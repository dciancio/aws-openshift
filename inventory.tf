locals {
  master_node_group   = "openshift_node_group_name=\"node-config-master\""
  infra_node_group    = "openshift_node_group_name=\"node-config-infra\""
  compute_node_group  = "openshift_node_group_name=\"node-config-compute\""
  master_node_labels  = ""
  infra_node_labels   = "openshift_node_labels=\"{'region': 'infra', 'zone': 'default'}\""
  compute_node_labels = "openshift_node_labels=\"{'region': 'primary', 'zone': 'default'}\""
  infra_region_nodeselector = "{'region':'infra'}"
  infra_role_nodeselector   = "{'node-role.kubernetes.io/infra':'true'}"
  logging_master_public_url = "openshift_logging_master_public_url=https://${local.public_admin_hostname}"
}
data "template_file" "aws_config" {
  count = "${var.cloudprovider == "aws" ? 1 : 0 }"
  template = "${file("${path.cwd}/helper_scripts/aws_config.template")}"
  vars = {
    cloudprovider = "${var.cloudprovider}"
    clusterid = "${var.clustername}"
  }
}
data "template_file" "custom_certs" {
  count = "${var.use_customcerts ? 1 : 0 }"
  template = "${file("${path.cwd}/helper_scripts/custom_certs.template")}"
  vars = {
    master_certfile = "${lookup(var.mastercert, "certfile")}"
    master_keyfile  = "${lookup(var.mastercert, "keyfile")}"
    master_names    = "${lookup(var.mastercert, "names")}"
    master_cafile   = "${lookup(var.mastercert, "cafile")}"
    router_certfile = "${lookup(var.routercert, "certfile")}"
    router_keyfile  = "${lookup(var.routercert, "keyfile")}"
    router_cafile   = "${lookup(var.routercert, "cafile")}"
  }
}
data "template_file" "oreg" {
  count = "${var.ocp_version == "3.10" || var.ocp_version == "3.11" ? 1 : 0 }"
  template = "${file("${path.cwd}/helper_scripts/oreg.template")}"
  vars = {
    reguser = "${var.reguser}"
    regpass = "${var.regpass}"
  }
}
data "template_file" "registry" {
  count = "${var.use_s3_registry ? 1 : 0 }"
  template = "${file("${path.cwd}/helper_scripts/registry.template")}"
  vars = {
    s3bucketname = "${var.s3bucketname}"
    aws_region = "${var.aws_region}"
  }
}
data "template_file" "metrics" {
  count = "${var.install_metrics ? 1 : 0 }"
  template = "${file("${path.cwd}/helper_scripts/metrics.template")}"
  vars = {
    nodeselector = "${var.ocp_version == "3.10" || var.ocp_version == "3.11" ? local.infra_role_nodeselector : local.infra_region_nodeselector }"
  }
}
data "template_file" "monitoring" {
  count = "${var.install_monitoring && (var.ocp_version == "3.10" || var.ocp_version == "3.11") ? 1 : 0 }"
  template = "${file("${path.cwd}/helper_scripts/monitoring.template")}"
}
data "template_file" "logging" {
  count = "${var.install_logging ? 1 : 0 }"
  template = "${file("${path.cwd}/helper_scripts/logging.template")}"
  vars = {
    nodeselector = "${var.ocp_version == "3.10" || var.ocp_version == "3.11" ? local.infra_role_nodeselector : local.infra_region_nodeselector }"
    logging_url  = "${var.ocp_version == "3.6" ? local.logging_master_public_url : "" }"
  }
}
data "template_file" "masters" {
  count = "${var.master_count}"
  template = "${file("${path.cwd}/helper_scripts/masters.template")}"
  vars = {
    master = "${element(aws_instance.master.*.private_dns, count.index)}"
  }
}
data "template_file" "nodes_master" {
  count = "${var.master_count}"
  template = "${file("${path.cwd}/helper_scripts/nodes_master.template")}"
  vars = {
    master = "${element(aws_instance.master.*.private_dns, count.index)}"
    oshost = "${var.ocp_version != "3.10" && var.ocp_version != "3.11"? format("%s=%s","openshift_hostname",element(aws_instance.master.*.private_dns, count.index)) : "" }"
    extra = "${var.ocp_version == "3.10" || var.ocp_version == "3.11" ? local.master_node_group : local.master_node_labels }"
  }
}
data "template_file" "nodes_infra" {
  count = "${var.infra_count}"
  template = "${file("${path.cwd}/helper_scripts/nodes_infra.template")}"
  vars = {
    infra = "${element(aws_instance.infra.*.private_dns, count.index)}"
    oshost = "${var.ocp_version != "3.10" && var.ocp_version != "3.11"? format("%s=%s","openshift_hostname",element(aws_instance.infra.*.private_dns, count.index)) : "" }"
    extra = "${var.ocp_version == "3.10" || var.ocp_version == "3.11" ? local.infra_node_group : local.infra_node_labels }"
  }
}
data "template_file" "nodes_worker" {
  count = "${var.worker_count}"
  template = "${file("${path.cwd}/helper_scripts/nodes_worker.template")}"
  vars = {
    worker = "${element(aws_instance.worker.*.private_dns, count.index)}"
    oshost = "${var.ocp_version != "3.10" && var.ocp_version != "3.11"? format("%s=%s","openshift_hostname",element(aws_instance.worker.*.private_dns, count.index)) : "" }"
    extra = "${var.ocp_version == "3.10" || var.ocp_version == "3.11" ? local.compute_node_group : local.compute_node_labels }"
  }
}
data "template_file" "inventory" {
  template = "${file("${path.cwd}/helper_scripts/ansible-hosts.template")}"
  vars = {
    aws_config = "${join("",data.template_file.aws_config.*.rendered)}"
    oreg = "${join("",data.template_file.oreg.*.rendered)}"
    ocp_version = "${var.ocp_version}"
    sdn_type = "${var.sdn_type}"
    public_subdomain = "${local.public_subdomain}"
    public_admin_hostname = "${local.public_admin_hostname}"
    admin_hostname = "${local.admin_hostname}"
    masters = "${join("",data.template_file.masters.*.rendered)}"
    nodes_master = "${join("",data.template_file.nodes_master.*.rendered)}"
    nodes_infra = "${join("",data.template_file.nodes_infra.*.rendered)}"
    nodes_worker = "${join("",data.template_file.nodes_worker.*.rendered)}"
    htpasswd = "${var.ocp_version == "3.10" || var.ocp_version == "3.11" ? "" : ", 'filename': '/etc/origin/master/htpasswd'"}"
    cacertexpiry = "${var.cacertexpiry}"
    certexpiry = "${var.certexpiry}"
    custom_certs = "${join("",data.template_file.custom_certs.*.rendered)}"
    registry = "${join("",data.template_file.registry.*.rendered)}"
    metrics = "${join("",data.template_file.metrics.*.rendered)}"
    monitoring = "${join("",data.template_file.monitoring.*.rendered)}"
    logging = "${join("",data.template_file.logging.*.rendered)}"
  }
}
resource "local_file" "inventory" {
  content  = "${data.template_file.inventory.rendered}"
  filename = "${path.cwd}/inventory/ansible-hosts"
}
