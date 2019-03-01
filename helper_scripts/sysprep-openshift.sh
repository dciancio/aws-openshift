#!/usr/bin/env bash

exec >/var/log/cloud-init-output.log 2>&1

HN=$(curl http://169.254.169.254/latest/meta-data/hostname)
sudo hostnamectl set-hostname $${HN}.${ec2domain}

sudo rpm -e rh-amazon-rhui-client
sudo yum clean all
sudo rm -rf /var/cache/yum

sudo subscription-manager register --activationkey='${rhak}' --org='${rhorg}' --force
sudo subscription-manager status
sudo subscription-manager repos --disable="*"
sudo subscription-manager repos \
    --enable="rhel-7-server-rpms" \
    --enable="rhel-7-server-extras-rpms" \
    --enable="rhel-7-fast-datapath-rpms" \
    --enable="rhel-7-server-ose-${ocp_version}-rpms" \
    --enable="rhel-7-server-ansible-${ansible_version}-rpms" 

sudo yum update -y
sudo yum install -y wget git net-tools bind-utils yum-utils iptables-services bridge-utils bash-completion kexec-tools sos psacct

sudo yum install -y docker NetworkManager

sudo systemctl stop docker
sudo systemctl enable docker
sudo rm -rf /var/lib/docker
sudo mkdir /var/lib/docker
sudo wipefs -a /dev/xvdf
sudo bash -c 'cat <<EOF > /etc/sysconfig/docker-storage-setup
STORAGE_DRIVER=overlay2
DEVS=/dev/xvdf
VG=dockervg
CONTAINER_ROOT_LV_NAME=dockerlv
CONTAINER_ROOT_LV_SIZE=100%FREE
CONTAINER_ROOT_LV_MOUNT_PATH=/var/lib/docker
EOF'
sudo docker-storage-setup
sudo systemctl restart docker

sudo reboot

