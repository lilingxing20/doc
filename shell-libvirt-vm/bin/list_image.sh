#!/bin/bash

set +x

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)
. ${SCRIPTS_DIR}/../lib/common.sh
. ${SCRIPTS_DIR}/../var/env.sh


vol_list=$(virsh vol-list --pool "$POOL_NAME" --details)
echo "$vol_list" | sed -n 1,2p
echo "$vol_list" | awk "/${IMAGE_PREFIX}/{print}"
