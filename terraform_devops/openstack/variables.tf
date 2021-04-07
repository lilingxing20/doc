#================================#
# Openstack prodvider的相关信息 #
#================================#
variable "openstack-user" {
  type        = string
  description = "openstack user name"
}
variable "openstack-tenant-name" {
  type        = string
  description = "openstack user name"
}
variable "openstack-password" {
  type        = string
  description = "openstack user password"
}
variable "openstack-auth-url" {
  type        = string
  description = "openstack-auth-url"
}
variable "openstack-region" {
  type        = string
  description = "openstack region"
}

#================================#
# Openstack flavor的相关信息 #
#================================#
variable "openstack-flavor-name" {
  type        = string
  description = "openstack flavor name"
}
variable "openstack-flavor-ram" {
  type        = string
  description = "ram of VM"
  default     =  8096
}
variable "openstack-flavor-vcpus" {
  type        = string
  description = "vcpus of VM"
  default     =  2
}
variable "openstack-flavor-disk" {
  type        = string
  description = "disk of VM"
  default     =  50
}

#================================#
# Openstack keypair的相关信息 #
#================================#
variable "openstack-keypair-name" {
  type        = string
  description = "openstack-keypair-name"
}


#================================#
# Openstack image的相关信息 #
#================================#
variable "openstack-image-name" {
  type        = string
  description = "openstack-image-name"
  default = ""
}
variable "openstack-image-source-url" {
  type        = string
  description = "openstack-image-source-url"
  default = ""
}
variable "openstack-image-container-format" {
  type        = string
  description = "openstack-image-container-format"
  default = ""
}
variable "openstack-image-disk-format" {
  type        = string
  description = "openstack-image-container-format"
  default = ""
}

#================================#
# openstack network网络相关信息#
#================================#
variable "openstack-network-name" {
  type        = string
  description = "openstack-network-name"
}
variable "openstack-subnet-name" {
  type        = string
  description = "openstack-subnet-name"
}


#================================#
# Openstack security-groups的相关信息 #
#================================#
variable "openstack-security-groups" {
  type = list
  description = "openstack-security-groups"
}

variable "openstack-security-group-name1"{
  type        = string
  description = "openstack-security-group-name1"
}
variable "openstack-security-group-name2"{
  type        = string
  description = "openstack-security-group-name2"
}

#================================#
# Openstack port组的相关信息 #
#================================#

variable "openstack-network-port" {
  type        = string
  description = "penstack-network-port"
  default     = ""
}

#================================#
# openstack 拟生成virtual machine 相关信息#
#================================#

variable "vm-count" {
  type        = string
  description = "Number of VM"
  default     =  1
}

variable "vm-name-prefix" {
  type        = string
  description = "Name of VM prefix"
  default     =  "openstack-vm-7601"
}

variable "vm-disk-size" {
  type        = string
  description = "Amount of Disk for the vSphere virtual machines (example: 80)"
  default     = "50"
}

variable "all_ips" {
  type = list
  description = "The all VM ip"
}

variable "vm-default-pass"{
   type        = string
   description = "新建虚机root用认的密码"
}

variable "openstack-image-id"{
   type        = string
   description = "新建虚机openstack-image-id "
}
