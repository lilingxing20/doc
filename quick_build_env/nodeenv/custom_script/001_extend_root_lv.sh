#!/bin/env bash
## by lixx
# 2017-01-03
#

start_time="$(date -u +%s)"

function writing_log(){
    echo "$(date +%F,%T),$LINENO: $@" >>/var/log/extend_root_lv.log
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

VG_PATH_TO_EXTEND=$(lvdisplay | grep 'LV Path' | awk '{print $NF}' | grep root)
ret=$(lvresize -l +100%FREE $VG_PATH_TO_EXTEND  2>&1)
check_execution_result
writing_log "lvresize run info: $ret"

ret=$(xfs_growfs $VG_PATH_TO_EXTEND  2>&1)
writing_log "The size of the online adjustment of XFS file system: $ret"

writing_log "$(lvs)"
writing_log "$(df -h)"

rm -f $0

end_time="$(date -u +%s)"
writing_log "Time elapsed $(($end_time-$start_time)) second"
