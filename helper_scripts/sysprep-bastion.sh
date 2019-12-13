#!/usr/bin/env bash

set -e

err_msg() {
  echo "FAILED - Error on line $(caller)"
  touch /root/sysprep_failed.txt
}

trap err_msg ERR

exec >/var/log/cloud-init-output.log 2>&1

rm -f /root/sysprep_*.txt

HN=$(curl http://169.254.169.254/latest/meta-data/hostname)
hostnamectl set-hostname $${HN}${ec2domain}

rpm -q rh-amazon-rhui-client && rpm -e rh-amazon-rhui-client

grep server_timeout /etc/rhsm/rhsm.conf || subscription-manager config --server.server_timeout=360
subscription-manager status || subscription-manager register --activationkey='${rhak}' --org='${rhorg}'
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

sed -i 's/^#compress/compress/g' /etc/logrotate.conf

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

su - ec2-user bash -c "[ -h ~/openshift-ansible ] || ln -s /usr/share/ansible/openshift-ansible"

cd /root
rm -rf /usr/local/aws
rm -f /usr/local/bin/aws
rm -rf awscli-bundle
rm -f awscli-bundle.zip
curl "https://s3.amazonaws.com/aws-cli/awscli-bundle.zip" -o "awscli-bundle.zip"
unzip awscli-bundle.zip
./awscli-bundle/install -i /usr/local/aws -b /usr/local/bin/aws

su - ec2-user bash -c "curl https://get.acme.sh | sh"

# Loop until all nodes syspreps have completed
echo "WAITING FOR NODE SYSPREP TO COMPLETE..."
timeout 1h bash -c "until su - ec2-user bash -c \"ansible -i hosts nodes -m shell -a 'cat /root/sysprep_complete.txt' &>/dev/null\"; do echo \"Waiting 60s...\"; sleep 60; done"

echo "COMPLETED"

/bin/cp -pf /etc/rc.d/rc.local /etc/rc.d/rc.local.orig
cat >>/etc/rc.d/rc.local <<EOF
touch /root/sysprep_complete.txt
/bin/mv -f /etc/rc.d/rc.local.orig /etc/rc.d/rc.local
chmod -x /etc/rc.d/rc.local
EOF

chmod +x /etc/rc.d/rc.local

reboot

