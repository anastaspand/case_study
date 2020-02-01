#!/bin/bash/
yum install yum-utils device-mapper-persistent-data lvm2 -y

### Add Docker repository.
yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo -y
  
## Install Docker CE.
yum update -y && sudo yum install docker-ce-18.06.2.ce -y
## Create /etc/docker directory.
mkdir /etc/docker

# Setup daemon. Login as root
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
  }
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart Docker
systemctl daemon-reload
systemctl restart docker
#enable docker startup
systemctl enable --now docker

#Installing kubeadm, kubelet and kubectl
#Add the kubernetes repo needed to find the kubelet, kubeadm and kubectl packages
cat <<EOF > /etc/yum.repos.d/kubernetes.repo
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

#Set SELinux in permissive mode (effectively disabling it). Login as root
setenforce 0
sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes -y
systemctl enable --now kubelet

#Some users on RHEL/CentOS 7 have reported issues with traffic being routed incorrectly due to iptables being bypassed. 
cat <<EOF >  /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system
