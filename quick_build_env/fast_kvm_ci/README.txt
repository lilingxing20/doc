快速部署Ceph集群
================


# 一、快速准备 KVM 虚拟化环境

## 0、系统环境
CentOS 7.6.1810 (Minimal安装方式)

## 1、初始化环境
安装 KVM 虚拟化环境
./install_kvm_env.sh

安装 vbmc 虚拟化环境(需要配置YUM源)
./install_vbmc_env.sh

创建网络
./make_kvm_net.sh

## 2、配置网桥
./set_bridge.sh <eth0> <br100>
./set_bridge.sh <eth1> <br200>


# 二、快速部署 Ceph 集群环境

## 1、规划节点环境配置
参考 ./scene/nodes.sample , 在 ./scene/ 目录创建新文件，如newpoc

【注意】部署节点主机名必须为depoly

## 2、开始部署
./create_vm_node.sh scene/newpoc

【注】清除环境
./clean_vm_node.sh scene/newpoc


# 三、KVM 虚拟机管理

## 1、查看虚拟机列表
virsh list --all

## 2、启动虚拟机
virsh start <Name/Id>

## 3、关闭虚拟机
virsh destroy <Name/Id>
