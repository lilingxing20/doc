
# ======================== #
# openstack configuration #
# ======================== #
openstack-user = "admin"
openstack-password = "passw0rd"
openstack-tenant-name = "admin"
openstack-auth-url = "http://172.30.126.150:5000/v3"
openstack-region = "RegionOne"

# ============================ #
# VM Custom Notes              #
# ============================ #
openstack-flavor-name = "flavor-2C8G50G"
openstack-flavor-ram = "8192"
openstack-flavor-vcpus = "2"
openstack-flavor-disk = "50"

openstack-keypair-name = "deploynodekey"
openstack-image-name = "CentOS-7-x86_64-GenericCloud-2003-qcow2"
openstack-image-id = "6716C86B-2548-41A8-B371-8965E46F8CE3"
openstack-image-container-format = "bare"
openstack-image-disk-format = "qcow2"

openstack-network-name = "vlan222-net"
openstack-subnet-name = "vlan222-subnet"

openstack-security-groups = ["test01", "test02"]
openstack-security-group-name1 = "test01"
openstack-security-group-name2 = "test02"
openstack-network-port = "vmport"

vm-count = 1
vm-name-prefix = "test"
vm-disk-size = 50
vm-default-pass = "passw0rd"

all_ips = ["172.30.125.116","172.30.125.117","172.30.125.118"]
