#!/usr/bin/env bash

set -e

err_msg() {
  echo "FAILED - Error on line $(caller)"
}

trap err_msg ERR

exec >/var/log/cloud-init-output.log 2>&1

HN=$(curl http://169.254.169.254/latest/meta-data/hostname)
hostnamectl set-hostname $${HN}.${ec2domain}

rpm -q rh-amazon-rhui-client && rpm -e rh-amazon-rhui-client

subscription-manager register --activationkey='${rhak}' --org='${rhorg}'
subscription-manager status
subscription-manager repos --disable="*"
subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-fast-datapath-rpms" \
    --enable="rhel-7-server-ose-${ocp_version}-rpms" \
    --enable="rhel-7-server-ansible-${ansible_version}-rpms"

yum update -y
yum install -y openshift-ansible
yum install -y wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct unzip socat

su - ec2-user bash -c "cat >~/ansible.cfg <<EOF
[defaults]
log_path = ./ansible.log
host_key_checking = False
retry_files_enabled = False
gathering = smart
roles_path = roles

[ssh_connection]
ssh_args = -C -o ControlMaster=auto -o ControlPersist=900s -o GSSAPIAuthentication=no
pipelining = True
EOF"

su - ec2-user bash -c "ln -s /usr/share/ansible/openshift-ansible"

cd /root
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

su - ec2-user bash -c "curl https://get.acme.sh | sh"

echo "COMPLETED"

reboot

