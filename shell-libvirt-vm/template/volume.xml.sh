#!/bin/bash

#volume_name="test001.qcow2"
#volume_size=10737418240
volume_name=$1
volume_size=$2

vol_xml_file="/tmp/volume_$(date +%Y%m%d%H%M%S).xml"

cat > ${vol_xml_file} << EOF
<volume type='file'>
  <name>${volume_name}</name>
  <capacity unit='bytes'>${volume_size}</capacity>
  <target>
    <format type='qcow2'/>
    <compat>1.1</compat>
    <features/>
  </target>
</volume>
EOF

echo $vol_xml_file
