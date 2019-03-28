#!/usr/bin/env bash

set -e

exec >/var/log/cloud-init-output.log 2>&1

DEVICE="/dev/$(lsblk | grep -w disk | sort | tail -1 | awk '{print $1}')"

HN=$(curl http://169.254.169.254/latest/meta-data/hostname)
hostnamectl set-hostname $${HN}.${ec2domain}

rpm -q rh-amazon-rhui-client && rpm -e rh-amazon-rhui-client

subscription-manager register --activationkey='${rhak}' --org='${rhorg}' --force
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

yum install -y docker NetworkManager

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

reboot

