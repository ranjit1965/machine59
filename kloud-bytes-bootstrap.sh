#!/bin/bash

## !IMPORTANT ##
#
## This script is tested only in the generic/ubuntu2204 Vagrant box
## If you use a different version of Ubuntu or a different Ubuntu Vagrant box test this again
#

echo "[TASK 1] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

echo "[TASK 2] Stop and Disable firewall"
systemctl disable --now ufw >/dev/null 2>&1

echo "[TASK 3] Enable and Load Kernel modules"
cat >>/etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "[TASK 4] Add Kernel settings"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >/dev/null 2>&1


echo "[TASK 5] Add kubernetes repo"

# Install package

sudo apt-get update >/dev/null 2>&1
sudo apt-get install -y apt-transport-https ca-certificates curl gpg >/dev/null 2>&1


sudo install -p -m 0755 -d /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.30/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sudo chmod a+r /etc/apt/keyrings/kubernetes-apt-keyring.gpg
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.30/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list

echo "[TASK 6] Install kubeadm,kubectl, kubelet package"

sudo apt-get update >/dev/null 2>&1

sudo apt-get install -y kubelet=1.30.0-1.1 kubeadm=1.30.0-1.1 kubectl=1.30.0-1.1 >/dev/null 2>&1
sudo apt-mark hold kubelet kubeadm kubectl

sudo systemctl enable --now kubelet

echo "[TASK 7] Install containerd"

sudo apt-get update >/dev/null 2>&1

sudo mkdir -p /etc/containerd/
sudo apt-get install -y containerd
containerd config default | sudo tee /etc/containerd/config.toml >/dev/null 2>&1
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

sudo systemctl enable containerd
sudo systemctl restart containerd

echo "[TASK 8] Install net-tools components (ifconfig )"
apt install -qq -y net-tools >/dev/null 2>&1


echo "[TASK 9] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

echo "[TASK 9] Set root password"
echo -e "admin\nadmin" | passwd root >/dev/null 2>&1
echo "export TERM=xterm" >> /etc/bash.bashrc

echo "[TASK 10] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
192.168.59.100   k8s59master.example.com     k8s59master  km1
192.168.59.101   k8s59worker1.example.com    k8s59worker1 kw1
192.168.59.102   k8s59worker2.example.com    k8s59worker2 kw2
192.168.59.103   k8s59worker3.example.com    k8s59worker3 kw3
192.168.59.104   k8s59worker4.example.com    k8s59worker4 kw4
EOF

