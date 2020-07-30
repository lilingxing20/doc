#!/usr/bin/bash
#
# 用户、进程进程数
# check_nproc.sh
# Used for `ls -d /proc/[0-9]*/task/* | wc -l` monitoring
# Create by lixx at 2020-07


get_ceph_service_task() {
    NOW=$(date "+%Y-%m-%d,%H:%M:%S")
    ps -ef | grep '/usr/bin/ceph' | grep -v grep | awk '{print $2" "$8"@"$10}' | sed 's;/usr/bin/;;' | while read pid name
    do
        pid_task_num=$(ls -d /proc/${pid}/task/* 2>/dev/null | grep -v ^$ |wc -l)
        echo -e "${NOW} \t ${name} \t\t ${pid_task_num}"
    done
}


get_user_total_task() {
    username=${1-root}
    NOW=$(date "+%Y-%m-%d,%H:%M:%S")
    pid_task_total=0
    for pid in $(ps -ef | grep ^${username} | grep -v grep | awk '{print $2}')
    do
        pid_num=$(ls -d /proc/${pid}/task/* 2>/dev/null | grep -v ^$ |wc -l)
        pid_task_total=$(expr ${pid_num} + ${pid_task_total})
        # echo $pid, $pid_num, $pid_task_total
    done
    echo -e "${NOW} \t ${username}: \t\t\t ${pid_task_total}"
}

 
get_system_total_task() {
    NOW=$(date "+%Y-%m-%d,%H:%M:%S")
    pid_task_total=$(ls -d /proc/[0-9]*/task/* 2>/dev/null | wc -l)
    echo -e "${NOW} \t system: \t\t ${pid_task_total}"
}

echo "------------------------------------------------------------------"   
echo -e "CheckTime \t\t ProcessName \t\t ProcTaskNum"
get_ceph_service_task
echo
echo -e "CheckTime \t\t UserName \t\t TotalProcTaskNum"
get_user_total_task 'root'
get_user_total_task 'nova'
get_user_total_task 'cinder'
get_user_total_task 'neutron'
echo
echo -e "CheckTime \t\t System \t\t TotalProcTaskNum"
get_system_total_task
echo
