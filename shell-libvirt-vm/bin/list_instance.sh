#!/bin/bash

set +x

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)
. ${SCRIPTS_DIR}/../lib/common.sh
. ${SCRIPTS_DIR}/../var/env.sh


domin_list=$(virsh list)
echo "$domin_list" | sed -n 1,2p
echo "$domin_list" | awk "/${INSTANCE_PREFIX}/{print}"
