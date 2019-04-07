#!/bin/bash

if [ $UID -ne 0 ];then
    echo "error: the script must be run with root."
    exit 1
fi

read -p "please input the hotname: " _hostname
hostnamectl set-hostname $_hostname && \
yum install -y epel-release && \
yum install -y vim wget gcc iptables-service lrzsz git net-tools|| exit 1

systemctl stop postfix && systemctl disable postfix
systemctl stop chronyd && systemctl disable chronyd
systemctl stop firewalld && systemctl disable firewalld

sed -i "s/SELINUX=.*/SELINUX=disabled/" /etc/selinux/config
iptables -F && service iptables save

cat > ~/.vimrc << EOF
set ai
set nu
set tabstop=4
set shiftwidth=4
set expandtab
EOF

cat > /etc/security/limits.d/all-nofile.conf << EOF
* hard nofile 65536
* soft nofile 65536
EOF

cp -rf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

clear
echo "restart the machine is the change takes effect!"
