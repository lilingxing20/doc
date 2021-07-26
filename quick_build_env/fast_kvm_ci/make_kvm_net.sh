#!/bin/bash


brctl addbr br-pxe
cat >pxe.xml<<EOF
<network> 
  <name>pxe</name> 
  <forward mode='bridge'/> <bridge name='br-pxe'/> 
  <portgroup name='vm' default='yes'/>
</network>
EOF
virsh net-define pxe.xml
virsh net-start pxe
virsh net-autostart pxe
ip link set br-pxe up
ip a add 192.168.40.254/24 dev br-pxe
rm -f pxe.xml


brctl addbr br-mgmt
cat >mgmt.xml<<EOF
<network> 
  <name>mgmt</name> 
  <forward mode='bridge'/> <bridge name='br-mgmt'/> 
  <portgroup name='vm' default='yes'/>
</network>
EOF
virsh net-define mgmt.xml
virsh net-start mgmt
virsh net-autostart mgmt
ip link set br-mgmt up
ip a add 192.168.41.254/24 dev br-mgmt
rm -f mgmt.xml


brctl addbr br-tenant
cat >tenant.xml<<EOF
<network>
  <name>tenant</name>
  <forward mode='bridge'/> <bridge name='br-tenant'/>
  <portgroup name='vm' default='yes'/>
</network>
EOF
virsh net-define tenant.xml
virsh net-start tenant
virsh net-autostart tenant
ip link set br-tenant up
rm -f tenant.xml


brctl addbr br-storpub
cat >storpub.xml<<EOF
<network> 
  <name>storpub</name> 
  <forward mode='bridge'/> <bridge name='br-storpub'/> 
  <portgroup name='vm' default='yes'/>
</network>
EOF
virsh net-define storpub.xml
virsh net-start storpub
virsh net-autostart storpub
ip a add 192.168.42.254/24 dev br-storpub 
rm -f  storpub.xml

brctl addbr br-storpri
cat >storpri.xml<<EOF
<network> 
  <name>storpri</name> 
  <forward mode='bridge'/> <bridge name='br-storpri'/> 
  <portgroup name='vm' default='yes'/>
</network>
EOF
virsh net-define storpri.xml
virsh net-start storpri
virsh net-autostart storpri
ip a add 192.168.43.254/24 dev br-storpri
rm -f  storpri.xml

