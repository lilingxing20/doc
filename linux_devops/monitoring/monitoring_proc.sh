#!/usr/bin/bash
# Create by lixx at 2020-07
#
# 监控指定用户、进程的打开文件数、任务数
#
# monitoring_proc.sh
# Open files: `ls -d /proc/[0-9]*/fd/*|wc -l`
# Proc tasks: `ls -d /proc/[0-9]*/task/*|wc -l`
#
# 每五分钟定时执行
# [root@locahost ~]# crontab -l
# */5 * * * * /home/lixx/monitoring_proc.sh
#

# 记录运行日志
RUN_LOG_FILE='/var/log/monitoring_proc.log'
# 定义输出目录时，输出到文件；未定义时，输出到终端。
LOG_DIR='/var/log/monitoring_proc/'
NOW_DATE=$(date "+%Y%m%d")

# 清除 7 天以前的记录
AGO_DATE=$(date -d "7 day ago" +%Y%m%d)

out_put_l() {
    if test -z "$LOG_DIR"
    then
        # 紫色分割字符
        printf "\033[35m%s\033[0m\n" $1
    else
        printf "%s\n" "$1" >> ${LOG_DIR}${NOW_DATE}
    fi
}
out_put_h() {
    if test -z "$LOG_DIR"
    then
        # 蓝色标题
        printf "\033[34m%-20s \t %-20s \t %16s \t %16s \033[0m\n" "$1" "$2" "$3" "$4"
    else
        printf "%-20s \t %-20s \t %16s \t %16s\n" "$1" "$2" "$3" "$4" >> ${LOG_DIR}${NOW_DATE}
    fi
}
out_put_c() {
    if test -z "$LOG_DIR"
    then
        # 绿色 天蓝色
        printf "\033[32m%-20s \033[0m \t \033[36m%-20s \033[0m \t %16s \t %16s\n" "$1" "$2" "$3" "$4"
    else
        printf "%-20s \t %-20s \t %16s \t %16s\n" "$1" "$2" "$3" "$4" >> ${LOG_DIR}${NOW_DATE}
    fi
}
out_put_a() {
    if test -z "$LOG_DIR"
    then
        echo -e "$@\n"
    else
        echo -e "$@\n" >> ${LOG_DIR}${NOW_DATE}
    fi
}
run_log()  {
    NOW=$(date "+%Y-%m-%d,%H:%M:%S")
    echo $NOW, $@ >> $RUN_LOG_FILE
}

check_log_dir() {
    if test -n "$LOG_DIR"
    then
        test -d $LOG_DIR || mkdir -p $LOG_DIR
        touch ${LOG_DIR}${NOW_DATE}
        for logfile in $(ls $LOG_DIR)
        do
            if [ "$logfile" -lt "$AGO_DATE" ]
            then
                 rm -f ${LOG_DIR}${logfile}
                 run_log "Clear log", $logfile, $?
            fi
        done
    fi
}


#### 收集系统信息 ####

ulimit_all() {
    run_log "Running ulimit -a."
    #ulimit -a >>${LOG_DIR}${NOW_DATE}
    ret=$(ulimit -a)
    out_put_a "$ret"
}

get_ceph_service() {
    run_log "Running get_ceph_service."
    NOW=$(date "+%Y-%m-%d,%H:%M:%S")
    ps -ef | grep '/usr/bin/ceph' | grep -v '/bin/bash' | grep -v grep | awk '{print $2" "$8"@"$10}' | sed 's;/usr/bin/;;' | while read pid name
    do
        pid_fd_num=$(ls -d /proc/${pid}/fd/* 2>/dev/null | wc -l)
        pid_task_num=$(ls -d /proc/${pid}/task/* 2>/dev/null | wc -l)
        # pid_task_num=$(pstree -p ${pid} | wc -l) # 执行较慢
        #echo -e "${NOW} \t ${name} \t\t ${pid_fd_num} \t\t ${pid_task_num}"
        out_put_c "${NOW}" "${name}" "${pid_fd_num}" "${pid_task_num}"
    done
}


get_user_total() {
    username=${1-root}
    run_log "Running get_user_total: $username"
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
    out_put_c "${NOW}" "${username}" "${fd_total}" "${task_total}"
}

 
get_system_total() {
    run_log "Running get_system_total"
    NOW=$(date "+%Y-%m-%d,%H:%M:%S")
    sys_fd_total=$(ls -d /proc/[0-9]*/fd/* 2>/dev/null | wc -l)
    sys_task_total=$(ls -d /proc/[0-9]*/task/* 2>/dev/null | wc -l)
    #echo -e "${NOW} \t system: \t\t ${sys_fd_total} \t\t\t ${sys_task_total}"
    out_put_c "${NOW}" "system" "${sys_fd_total}" "${sys_task_total}"
}

monitoring_proc_main() {
    check_log_dir
    out_put_l "------------------------------------------------------------------------------------------"
    out_put_h "Current system configuration"
    ulimit_all
    out_put_h "CheckTime" "ProcessName" "ProcFd" "ProcTask"
    get_ceph_service
    out_put_l
    out_put_h "CheckTime" "UserName" "TotalProcFd" "TotalProcTask"
    get_user_total 'root'
    get_user_total 'nova'
    get_user_total 'cinder'
    get_user_total 'neutron'
    out_put_l
    out_put_h "CheckTime" "System" "TotalProcFd" "TotalProcTask"
    get_system_total
    out_put_l
}

#### main ####
monitoring_proc_main

