#!/bin/env bash
# v1: 2019-7
# v2: 2019-7  add get_ceph_conf,get_ceph_daemon_conf

echo "#####################################"
echo "#    Ceph Cluster Info Collector    #"
echo "#####################################"

RUN_DATE=$(date "+%Y-%m-%d-%H-%M-%S")
echo -e "\nRUN DATE: $RUN_DATE\n"

CEPH_CMD="ceph --connect-timeout 5 "
CEPH_CMD_JSON="ceph --connect-timeout 5 -f json "
CEPH_CMD_JSON_PRETTY="ceph --connect-timeout 5 -f json-pretty "

BASE_DIR=$(cd `dirname $0` && pwd)
TMP_DIR="${BASE_DIR}/$RUN_DATE"
CEPH_INFO_TAR=${TMP_DIR}.tar.gz

if [ -f ${TMP_DIR} ]; then
    echo "This Dir or file exists: $TMP_DIR"
    exit 1
else
    mkdir -p ${TMP_DIR}
fi

function get_osds() {
    # get mon daemon
    $CEPH_CMD osd dump | awk '/^osd\.[0-9]+/ { match($0,/osd\.[0-9]+/); osd_daemon=substr($0, RSTART, RLENGTH); print osd_daemon}'
}

function get_mons() {
    # get mon daemon
    $CEPH_CMD mon dump | awk '/^[0-9]+:/ { match($0,/mon\.[0-9a-fA-F]+/); mon_daemon=substr($0, RSTART, RLENGTH); print mon_daemon}'
}

function get_ceph_version() {
    echo "Ceph Version Info Collector: $TMP_DIR"
    cd $TMP_DIR
    ceph version >ceph_version.txt
}

function get_mon_info() {
    tmp_mon_dir="$TMP_DIR/mon"
    mkdir -p $tmp_mon_dir
    cd $tmp_mon_dir
    echo "Ceph MON Info Collector: $(pwd)"
    # mon stat
    # $CEPH_CMD             mon stat >mon_stat.txt
    # $CEPH_CMD_JSON        mon stat >mon_stat_json.txt
    # $CEPH_CMD_JSON_PRETTY mon stat >mon_stat_json_pretty.txt
    $CEPH_CMD_JSON_PRETTY mon_status >mon_status_json_pretty.txt
    # mon dump
    $CEPH_CMD             mon dump >mon_dump.txt
    $CEPH_CMD_JSON        mon dump >mon_dump_json.txt
    $CEPH_CMD_JSON_PRETTY mon dump >mon_dump_json_pretty.txt
    # mon map
    $CEPH_CMD mon getmap -o monmap.bin
    cd $TMP_DIR
}

function get_osd_info() {
    tmp_osd_dir="$TMP_DIR/osd"
    mkdir -p $tmp_osd_dir
    cd $tmp_osd_dir
    echo "Ceph OSD Info Collector: $(pwd)"
    # osd stat
    $CEPH_CMD             osd stat >osd_stat.txt
    $CEPH_CMD_JSON        osd stat >osd_stat_json.txt
    $CEPH_CMD_JSON_PRETTY osd stat >osd_stat_json_pretty.txt
    # osd dump
    $CEPH_CMD             osd dump >osd_dump.txt
    $CEPH_CMD_JSON        osd dump >osd_dump_json.txt
    $CEPH_CMD_JSON_PRETTY osd dump >osd_dump_json_pretty.txt
    # osd tree
    $CEPH_CMD             osd tree >osd_tree.txt
    $CEPH_CMD_JSON        osd tree >osd_tree_json.txt
    $CEPH_CMD_JSON_PRETTY osd tree >osd_tree_json_pretty.txt
    # osd map
    $CEPH_CMD osd getmap -o osdmap.bin
    # crush map
    $CEPH_CMD osd getcrushmap -o crushmap.bin
    crushtool -d crushmap.bin -o crushmap.txt
    cd $TMP_DIR
}

function get_pool_info() {
    tmp_pool_dir="$TMP_DIR/pool"
    mkdir -p $tmp_pool_dir
    cd $tmp_pool_dir
    echo "Ceph POOL Info Collector: $(pwd)"
    # pool detail
    $CEPH_CMD             osd pool ls detail >pool_detail.txt
    $CEPH_CMD_JSON        osd pool ls detail >pool_detail_json.txt
    $CEPH_CMD_JSON_PRETTY osd pool ls detail >pool_detail_json_pretty.txt
    cd $TMP_DIR
}

function get_pg_info() {
    tmp_pg_dir="$TMP_DIR/pg"
    mkdir -p $tmp_pg_dir
    cd $tmp_pg_dir
    echo "Ceph PG Info Collector: $(pwd)"
    # pg dump
    $CEPH_CMD             pg dump >pg_dump.txt
    $CEPH_CMD_JSON        pg dump >pg_dump_json.txt
    $CEPH_CMD_JSON_PRETTY pg dump >pg_dump_json_pretty.txt
    cd $TMP_DIR
}

function get_df_info() {
    tmp_df_dir="$TMP_DIR/df"
    mkdir -p $tmp_df_dir
    cd $tmp_df_dir
    echo "Ceph Storage Info Collector: $(pwd)"
    # df
    $CEPH_CMD             df >df.txt
    $CEPH_CMD_JSON        df >df_json.txt
    $CEPH_CMD_JSON_PRETTY df >df_json_pretty.txt
    # osd df
    $CEPH_CMD             osd df >osd_df.txt
    $CEPH_CMD_JSON        osd df >osd_df_json.txt
    $CEPH_CMD_JSON_PRETTY osd df >osd_df_json_pretty.txt
    cd $TMP_DIR
}

function get_ceph_conf() {
    tmp_conf_dir="$TMP_DIR/conf/"
    mkdir -p $tmp_conf_dir
    cd $tmp_conf_dir
    echo "Ceph Configuration Info Collector: $(pwd)"
    # conf file
    ceph_conf_file='/etc/ceph/ceph.conf'
    if [ -f $ceph_conf_file ]; then
        cp -v $ceph_conf_file $tmp_conf_dir
    else
        echo "Not found ceph conf file: $ceph_conf_file !"
    fi
    cd $TMP_DIR
}

function get_ceph_daemon_conf() {
    tmp_conf_dir="$TMP_DIR/conf/"
    mkdir -p $tmp_conf_dir
    cd $tmp_conf_dir
    echo "Ceph Daemon Configuration Info Collector: $(pwd)"
    mons=$(get_mons)
    for i in $mons; do
        echo "ceph daemon $i config show"
        $CEPH_CMD daemon $i config show >$i
    done
    osds=$(get_osds)
    for i in $osds; do
        echo "ceph daemon $i config show"
        $CEPH_CMD daemon $i config show >$i
    done
    cd $TMP_DIR
}


### main ###

get_ceph_version
get_mon_info
get_osd_info
get_pool_info
get_pg_info
get_df_info
get_ceph_conf
get_ceph_daemon_conf

cd $BASE_DIR
tar -zcf $CEPH_INFO_TAR $RUN_DATE >/dev/null
test -f $CEPH_INFO_TAR && echo -e "\nCeph Cluster Info Collector Package: ${CEPH_INFO_TAR}\n"

# end
