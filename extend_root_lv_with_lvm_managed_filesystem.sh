#!/bin/env bash
## by lixx
# 2017-01-03
#

function writing_log(){
    echo "$(date +%F,%T),$LINENO: $@"
}


function check_execution_result(){
        if [[ ! -z $RETVAL ]]; then
                unset RETVAL
        fi

        RETVAL=$?
        if [[ $RETVAL -ne 0 ]]; then
                writing_log "execution failed! $RETVAL"
                exit $RETVAL
        else
                writing_log "execution successfully! "
        fi
        unset RETVAL
}



writing_log "$(lvs)"

ONLINE_SCSI_DISK_PRESENT=$(lsblk --all | grep disk | grep -v fd | awk '{print $1}' | xargs)
ONLINE_SCSI_DISK_PRESENT_FILENAME="/dev/"$ONLINE_SCSI_DISK_PRESENT
ONLINE_SCSI_DISK_PARTITION_LARGEST_ID=$(lsblk --all | grep part | grep -v fd  | awk '{print $1}' | sed 's/[^1-9]*//'| tail -1| xargs)
writing_log "Create a device sda new partition."

ret=$(fdisk $ONLINE_SCSI_DISK_PRESENT_FILENAME 2>&1<<eof
n
p



t

8e
p
w
eof
)

check_execution_result
writing_log "fdisk run info: $ret"

ret=$(partprobe -s $ONLINE_SCSI_DISK_PRESENT_FILENAME)
writing_log "partprobe -s run status: $?"
writing_log "partprobe -s run info: $ret"

NEW_SCSI_DISK_PARTITION_ID=$(lsblk --all | grep part | grep -v fd  | awk '{print $1}' | sed 's/[^1-9]*//'| tail -1| xargs)
if [ "$NEW_SCSI_DISK_PARTITION_ID" == "$ONLINE_SCSI_DISK_PARTITION_LARGEST_ID" ]
then
    writing_log "Don't need to be extended partition."
    exit 0
fi

NEW_SCSI_DISK_PARTITION_FILENAME=${ONLINE_SCSI_DISK_PRESENT_FILENAME}${NEW_SCSI_DISK_PARTITION_ID}
VG_Name=$(vgdisplay | grep 'VG Name' | awk '{print $NF}')
ret=$(vgextend $VG_Name $NEW_SCSI_DISK_PARTITION_FILENAME 2>&1)
check_execution_result
writing_log "vgextend run info: $ret"

VG_PATH_TO_EXTEND=$(lvdisplay | grep 'LV Path' | awk '{print $NF}' | grep root)
ret=$(lvresize -l +100%FREE $VG_PATH_TO_EXTEND  2>&1)
check_execution_result
writing_log "lvresize run info: $ret"

ret=$(xfs_growfs $VG_PATH_TO_EXTEND  2>&1)
writing_log "The size of the online adjustment of XFS file system: $ret"

writing_log "$(lvs)"
writing_log "$(df -h)"

