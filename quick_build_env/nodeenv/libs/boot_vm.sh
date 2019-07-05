# file_name: libs/boot_vm.sh

function boot_vm()
{
    vm_name=$1
    boot_disk=$2
    virt-install --connect qemu:///system \
                 --name ${vm_name} \
                 --virt-type=kvm \
                 --memballoon=virtio \
                 --vcpus 8 \
                 --ram 8192 \
                 --disk ${boot_disk},format=qcow2,bus=virtio,cache=none \
                 --disk pool=volpool,size=20,bus=virtio,sparse=false,cache=none,io=native,format=qcow2 \
                 --disk pool=volpool,size=20,bus=virtio,sparse=false,cache=none,io=native,format=qcow2 \
                 --disk pool=volpool,size=20,bus=virtio,sparse=false,cache=none,io=native,format=qcow2 \
                 --network network=pxe-net,model=virtio \
                 --network network=mgmt-net,model=virtio \
                 --network network=storage-net,model=virtio \
                 --network network=tenant-net,model=virtio \
                 --vnc \
                 --vnclisten=0.0.0.0 \
                 --vncport=-1 \
                 --os-type=linux \
                 --os-variant=rhel7 \
                 --boot hd \
                 --force \
                 --autostart \
                 --wait=0
}

$1
# vim: tabstop=4 shiftwidth=4 softtabstop=4
