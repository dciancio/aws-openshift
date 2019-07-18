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
hostnamectl set-hostname $${HN}.${ec2domain}

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
yum install -y wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct

sed -i 's/^#compress/compress/g' /etc/logrotate.conf

yum install -y docker NetworkManager

DEVICE="/dev/$(lsblk | grep -w disk | sort | tail -1 | awk '{print $1}')"

systemctl stop docker
systemctl enable docker
rm -rf /var/lib/docker
mkdir /var/lib/docker
wipefs -a $${DEVICE}
cat >/etc/sysconfig/docker-storage-setup <<EOF
STORAGE_DRIVER=overlay2
DEVS=$${DEVICE}
VG=dockervg
CONTAINER_ROOT_LV_NAME=dockerlv
CONTAINER_ROOT_LV_SIZE=100%FREE
CONTAINER_ROOT_LV_MOUNT_PATH=/var/lib/docker
EOF
docker-storage-setup
systemctl restart docker

echo "COMPLETED"

/bin/cp -pf /etc/rc.d/rc.local /etc/rc.d/rc.local.orig
cat >>/etc/rc.d/rc.local <<EOF
touch /root/sysprep_complete.txt
/bin/mv -f /etc/rc.d/rc.local.orig /etc/rc.d/rc.local
chmod -x /etc/rc.d/rc.local
EOF

chmod +x /etc/rc.d/rc.local

reboot

