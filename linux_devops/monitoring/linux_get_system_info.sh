#!/bin/bash
#
# V1.0
# create at 2020-12
#

## yum install sysstat
# /usr/bin/cifsiostat
# /usr/bin/iostat
# /usr/bin/mpstat
# /usr/bin/nfsiostat-sysstat
# /usr/bin/pidstat
# /usr/bin/sadf
# /usr/bin/sar
# /usr/bin/tapestat
#
## yum install net-tools
# /bin/netstat
# /sbin/arp
# /sbin/ether-wake
# /sbin/ifconfig
# /sbin/ipmaddr
# /sbin/iptunnel
# /sbin/mii-diag
# /sbin/mii-tool
# /sbin/nameif
# /sbin/plipconfig
# /sbin/route
# /sbin/slattach
#

SCRIPTS_DIR=$(cd $(dirname "$0") && pwd)
dir_name="$(hostname)_sysinfo_$(date +%Y%m%d%H%M%S)"
base_dir="${SCRIPTS_DIR}/${dir_name}"

test -d $base_dir || mkdir -p $base_dir 

uptime | tee $base_dir/uptime
echo "System startup time: $(uptime -s)" | tee $base_dir/uptime
echo "System running time: $(uptime -p)" | tee $base_dir/uptime

ps -ef | tee $base_dir/ps_ef
ps -xH | tee $base_dir/ps_xH

#
## cpu info
#
lscpu | tee $base_dir/lscpu
cat /proc/cpuinfo | tee $base_dir/proc_cpuinfo

#
## memory info
#
free -m | tee $base_dir/free_m
cat /proc/meminfo | tee $base_dir/proc_meminfo

#
## network info
#
ip -s link | tee $base_dir/ip_s_link
cat /proc/net/dev | tee $base_dir/proc_net_dev

#
## slabinfo
#
vmstat -m | tee $base_dir/vmstat_m
cat /proc/slabinfo | tee $base_dir/proc_slabinfo

#
## disk info
#
df -m | tee $base_dir/df_m
cat /proc/diskstats | tee $base_dir/proc_diskstats
# summarize disk statistics
vmstat -D | tee $base_dir/vmstat_D
vmstat -dwt | tee $base_dir/vmstat_d

#
## event counter statistics
#
vmstat -s | tee $base_dir/vmstat_s

#
## procs-memory-swap-io-system-cpu
#
# vmstat 1 60 | tee $base_dir/vmstat_1_60
vmstat -anwt 1 60 | tee $base_dir/vmstat_1_60

cat /proc/sys/kernel/threads-max | tee $base_dir/proc_sys_kernel_threads_max
cat /proc/sys/kernel/pid_max | tee $base_dir/proc_sys_kernel_pid_max
cat /proc/sys/fs/file-nr | tee $base_dir/proc_sys_fs_file_nr


#
## yum install sysstat
#
which mpstat >/dev/null 2>&1
if [ "$?" == "0" ]; then
    mpstat -u | tee $base_dir/mpstat_u
    mpstat -P ALL 1 60 | tee $base_dir/mpstat_P_ALL_1_60
fi
which iostat >/dev/null 2>&1
if [ "$?" == "0" ]; then
    iostat -xzt 1 60 | tee $base_dir/iostat_xz_1_60
fi
which sar >/dev/null 2>&1
if [ "$?" == "0" ]; then
    sar -b | tee $base_dir/sar_b
    sar -B | tee $base_dir/sar_B
    sar -d -p | tee $base_dir/sar_d_p
    sar -n DEV 1 60 | tee $base_dir/sar_n_DEV_1_60
    sar -q | tee $base_dir/sar_q
    sar -r | tee $base_dir/sar_r
    sar -R | tee $base_dir/sar_R
    sar -s | tee $base_dir/sar_s
    sar -u | tee $base_dir/sar_u
    sar -v | tee $base_dir/sar_v
    sar -w | tee $base_dir/sar_w
    sar -W | tee $base_dir/sar_W
fi

#
## yum install net-tools
#
which ifconfig >/dev/null 2>&1
if [ "$?" == "0" ]; then
    ifconfig | tee $base_dir/ifconfig
fi
which netstat >/dev/null 2>&1
if [ "$?" == "0" ]; then
    netstat -d | tee $base_dir/netstat_d
    netstat -i | tee $base_dir/netstat_i
    netstat -r | tee $base_dir/netstat_r
    netstat -s | tee $base_dir/netstat_s
    netstat -u | tee $base_dir/netstat_u
    netstat -w | tee $base_dir/netstat_w
fi

cd ${SCRIPTS_DIR}
tar zcvf ${dir_name}.tar.gz $dir_name
