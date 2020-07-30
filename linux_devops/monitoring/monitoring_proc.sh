#!/usr/bin/bash
# Create by lixx at 2020-07
#
# 监控指定用户、进程的打开文件数、任务数
#
# monitoring_proc.sh
# Open files: `ls -d /proc/[0-9]*/fd/*|wc -l`
# Proc tasks: `ls -d /proc/[0-9]*/task/*|wc -l`
#


out_put0() {
    printf "%20s\t%-20s\t\t%8s\t\t%8s\n" "$1" "$2" "$3" "$4"
}
out_put2() {
    # 蓝色标题
    printf "\033[34m%-20s \t %-20s \t %16s \t %16s \033[0m\n" "$1" "$2" "$3" "$4"
}
out_put3() {
    # 绿色 天蓝色
    printf "\033[32m%-20s \033[0m \t \033[36m%-20s \033[0m \t %16s \t %16s \n" "$1" "$2" "$3" "$4"
}

ulimit_all() {
    ulimit -a
}

get_ceph_service() {
    NOW=$(date "+%Y-%m-%d,%H:%M:%S")
    ps -ef | grep '/usr/bin/ceph' | grep -v grep | awk '{print $2" "$8"@"$10}' | sed 's;/usr/bin/;;' | while read pid name
    do
        pid_fd_num=$(ls -d /proc/${pid}/fd/* 2>/dev/null | wc -l)
        pid_task_num=$(ls -d /proc/${pid}/task/* 2>/dev/null | wc -l)
        # pid_task_num=$(pstree -p ${pid} | wc -l) # 执行较慢
        #echo -e "${NOW} \t ${name} \t\t ${pid_fd_num} \t\t ${pid_task_num}"
        out_put3 "${NOW}" "${name}" "${pid_fd_num}" "${pid_task_num}"
    done
}


get_user_total() {
    username=${1-root}
    NOW=$(date "+%Y-%m-%d,%H:%M:%S")
    fd_total=0
    task_total=0
    for pid in $(ps -ef | grep ^${username} | grep -v grep | awk '{print $2}')
    do
        pid_fd_num=$(ls -d /proc/${pid}/fd/* 2>/dev/null | wc -l)
        fd_total=$(expr ${pid_fd_num} + ${fd_total})
        pid_task_num=$(ls -d /proc/${pid}/task/* 2>/dev/null | wc -l)
        task_total=$(expr ${pid_task_num} + ${task_total})
        # echo $pid, $pid_fd_num, $fd_total, $pid_task_num, $task_total
    done
    #echo -e "${NOW} \t ${username}: \t\t\t ${fd_total} \t\t ${task_total}"
    out_put3 "${NOW}" "${username}" "${fd_total}" "${task_total}"
}

 
get_system_total() {
    NOW=$(date "+%Y-%m-%d,%H:%M:%S")
    sys_fd_total=$(ls -d /proc/[0-9]*/fd/* 2>/dev/null | wc -l)
    sys_task_total=$(ls -d /proc/[0-9]*/task/* 2>/dev/null | wc -l)
    #echo -e "${NOW} \t system: \t\t ${sys_fd_total} \t\t\t ${sys_task_total}"
    out_put3 "${NOW}" "system" "${sys_fd_total}" "${sys_task_total}"
}

echo -e "\033[35m------------------------------------------------------------------------------------------\033[0m"
out_put2 "Current system configuration"
ulimit_all
out_put2 "CheckTime" "ProcessName" "ProcFd" "ProcTask"
get_ceph_service
echo
out_put2 "CheckTime" "UserName" "TotalProcFd" "TotalProcTask"
get_user_total 'root'
get_user_total 'nova'
get_user_total 'cinder'
get_user_total 'neutron'
echo
out_put2 "CheckTime" "System" "TotalProcFd" "TotalProcTask"
get_system_total
echo
