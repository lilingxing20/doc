#!/bin/bash

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)
# . ${SCRIPTS_DIR}/../lib/common.sh
# . ${SCRIPTS_DIR}/../var/env.sh


virsh net-list --all
