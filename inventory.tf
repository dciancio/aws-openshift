locals {
  master_node_group   = "openshift_node_group_name=\"node-config-master\""
  infra_node_group    = "openshift_node_group_name=\"node-config-infra\""
  compute_node_group  = "openshift_node_group_name=\"node-config-compute\""
  master_node_labels  = ""
  infra_node_labels   = "openshift_node_labels=\"{'region': 'infra', 'zone': 'default'}\""
  compute_node_labels = "openshift_schedulable=true openshift_node_labels=\"{'region': 'primary', 'zone': 'default'}\""
}
data "template_file" "masters" {
  count = "${var.master_count}"
  template = "${file("${path.cwd}/helper_scripts/masters.template")}"
  vars {
    master = "${element(aws_instance.master.*.private_dns, count.index)}"
  }
}
data "template_file" "nodes_master" {
  count = "${var.master_count}"
  template = "${file("${path.cwd}/helper_scripts/nodes_master.template")}"
  vars {
    master = "${element(aws_instance.master.*.private_dns, count.index)}"
    extra = "${var.ocp_version == "3.10" || var.ocp_version == "3.11" ? local.master_node_group : local.master_node_labels }"
  }
}
data "template_file" "nodes_infra" {
  count = "${var.infra_count}"
  template = "${file("${path.cwd}/helper_scripts/nodes_infra.template")}"
  vars {
    infra = "${element(aws_instance.infra.*.private_dns, count.index)}"
    extra = "${var.ocp_version == "3.10" || var.ocp_version == "3.11" ? local.infra_node_group : local.infra_node_labels }"
  }
}
data "template_file" "nodes_worker" {
  count = "${var.worker_count}"
  template = "${file("${path.cwd}/helper_scripts/nodes_worker.template")}"
  vars {
    worker = "${element(aws_instance.worker.*.private_dns, count.index)}"
    extra = "${var.ocp_version == "3.10" || var.ocp_version == "3.11" ? local.compute_node_group : local.compute_node_labels }"
  }
}
data "template_file" "inventory" {
  template = "${file("${path.cwd}/helper_scripts/ansible-hosts.template")}"
  vars {
    cloudprovider = "${var.cloudprovider}"
    clusterid = "${var.clustername}"
    ocp_version = "${var.ocp_version}"
    sdn_type = "${var.sdn_type}"
    public_subdomain = "${local.public_subdomain}"
    admin_hostname = "${local.admin_hostname}"
    masters = "${join("",data.template_file.masters.*.rendered)}"
    nodes_master = "${join("",data.template_file.nodes_master.*.rendered)}"
    nodes_infra = "${join("",data.template_file.nodes_infra.*.rendered)}"
    nodes_worker = "${join("",data.template_file.nodes_worker.*.rendered)}"
    htpasswd = "${var.ocp_version == "3.10" || var.ocp_version == "3.11" ? "" : ", 'filename': '/etc/origin/master/htpasswd'"}"
  }
}
resource "local_file" "inventory" {
  content  = "${data.template_file.inventory.rendered}"
  filename = "${path.cwd}/inventory/ansible-hosts"
}
