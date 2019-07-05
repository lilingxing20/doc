## parse node ip info

net_type_arr=($(echo ${NODE_ARRAY}| awk '{print $NF}' | awk -F ";" '{for(i=1;i<=NF;i++){print $i}}'|awk -F ',' '{print $1}'))
net_num=${#net_type_arr[@]}

# NODE_ARRAY need in $1
NODE_NUM=$((${#NODE_ARRAY[@]}-1))
node_control_ip_arr=()
for idx in $(seq "$NODE_NUM"); do
    # echo "node: $idx"
    host_name=$(echo ${NODE_ARRAY[$idx]}| awk '{print $2}')
    net_arr=($(echo ${NODE_ARRAY[$idx]}| awk '{print $NF}' | awk -F ";" '{for(i=1;i<=NF;i++){print $i}}'|awk -F ',' '{print $1}'))
    # echo ${net_arr[*]}
    for i in $(seq 0 "$(($net_num-1))"); do 
        if [[ "${net_type_arr[$i]}" =~ control.* ]]; then
            if [ -z "$node_control_ip_arr" ]; then
                node_control_ip_arr=(${net_arr[$i]%%/*})
            else
                node_control_ip_arr=(${node_control_ip_arr[@]} ${net_arr[$i]%%/*})
            fi
            break
        fi
    done
done

