# ======================== #
# VMware VMs configuration #
# ======================== #

vm-count= "2"
vm-name = "tftest"
vm-template-name = "CentOS-76-vmx11-30G50G"
vsphere-template-folder = "Template"
vm-cpu = 2
vm-ram = 4096
vm-disk-size = 50
vm-guest-id = "centos64Guest"
vm-resource-pool = "Terraform"
vm-folder = ""
vsphere-datacenter = "DC01"
vsphere-cluster = "4A-HHBI-AP-CLUSTER-05"
vm-datastore = "nv7030_1_T1"
vm-network = "VM Network"
vm-domain = "corp.local"
vm-startip=  "172.30.126"       


vm-annotation = "Create by Terraform"

# ============================ #
# vm tags and category         #
# ============================ #
vm-tag-category = "terraform-test-category"
vm-tag-list = ["web-443", "web-80"]


# ============================ #
# VM Custom Notes              #
# ============================ #
vm-application = "WebServer"
vm-owner = "Terraform-user"

# ============================ #
# VMware vSphere configuration #
# ============================ #

# VMware vCenter IP/FQDN
vsphere-vcenter = "172.30.126.41"

# VMware vSphere username used to deploy the infrastructure
vsphere-user = "administrator@vsphere.local"

# VMware vSphere password used to deploy the infrastructure
vsphere-password = "P@ssw0rd"

# Skip the verification of the vCenter SSL certificate (true/false)
vsphere-unverified-ssl = "true"