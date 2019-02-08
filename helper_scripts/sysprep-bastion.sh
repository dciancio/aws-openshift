#!/usr/bin/env bash

exec >/var/log/cloud-init-output.log 2>&1

HN=$(curl http://169.254.169.254/latest/meta-data/hostname)
sudo hostnamectl set-hostname $${HN}.${ec2domain}

sudo rpm -e rh-amazon-rhui-client
sudo yum clean all
sudo rm -rf /var/cache/yum

sudo subscription-manager register --username='${rhuser}' --password='${rhpass}' --force
sudo subscription-manager attach --pool='${rhpool}'
sudo subscription-manager status
sudo subscription-manager repos --disable="*"
sudo subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-fast-datapath-rpms" \
    --enable="rhel-7-server-ose-${ocp_version}-rpms" \
    --enable="rhel-7-server-ansible-${ansible_version}-rpms"

sudo yum update -y
sudo yum install -y openshift-ansible
sudo yum install -y wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct unzip

sudo su - ec2-user bash -c 'cat <<EOF > ~/ansible.cfg
[defaults]
log_path = ./ansible.log
host_key_checking = False
retry_files_enabled = False
gathering = smart
roles_path = roles

[ssh_connection]
ssh_args = -C -o ControlMaster=auto -o ControlPersist=900s -o GSSAPIAuthentication=no
pipelining = True
EOF'

sudo su - ec2-user bash -c 'ln -s /usr/share/ansible/openshift-ansible'

curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
sudo ./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

sudo reboot

