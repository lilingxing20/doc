#!/usr/bin/bash
#
# 用户、进程打开文件数
# check_nofile.sh
# Used for `ls /proc/[0-9]*/fd/*|wc -l` monitoring
# Create by lixx at 2020-07


get_ceph_service_fd() {
    NOW=$(date "+%Y-%m-%d,%H:%M:%S")
    ps -ef | grep '/usr/bin/ceph' | grep -v grep | awk '{print $2" "$8"@"$10}' | sed 's;/usr/bin/;;' | while read pid name
    do
        pid_fd_num=$(ls -d /proc/${pid}/fd/* 2>/dev/null | grep -v ^$ |wc -l)
        echo -e "${NOW} \t ${name} \t\t ${pid_fd_num}"
    done
}


get_user_total_fd() {
    username=${1-root}
    NOW=$(date "+%Y-%m-%d,%H:%M:%S")
    pid_fd_total=0
    for pid in $(ps -ef | grep ^${username} | grep -v grep | awk '{print $2}')
    do
        pid_num=$(ls -d /proc/${pid}/fd/* 2>/dev/null | grep -v ^$ |wc -l)
        pid_fd_total=$(expr ${pid_num} + ${pid_fd_total})
        # echo $pid, $pid_num, $pid_fd_total
    done
    echo -e "${NOW} \t ${username}: \t\t\t ${pid_fd_total}"
}

 
get_system_total_fd() {
    NOW=$(date "+%Y-%m-%d,%H:%M:%S")
    pid_fd_total=$(ls -d /proc/[0-9]*/fd/* 2>/dev/null | wc -l)
    echo -e "${NOW} \t system: \t\t ${pid_fd_total}"
}

echo "------------------------------------------------------------------"   
echo -e "CheckTime \t\t ProcessName \t\t ProcFdNum"
get_ceph_service_fd
echo
echo -e "CheckTime \t\t UserName \t\t TotalProcFdNum"
get_user_total_fd 'root'
get_user_total_fd 'nova'
get_user_total_fd 'cinder'
get_user_total_fd 'neutron'
echo
echo -e "CheckTime \t\t System \t\t TotalProcFdNum"
get_system_total_fd
echo
