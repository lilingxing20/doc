#!/bin/bash

#conf_file_path='/etc/haproxy'
conf_file_path='.'
test -f "${conf_file_path}/haproxy.cfg" || exit 1
#mv ${conf_file_path}/haproxy.cfg ${conf_file_path}//haproxy.cfg.org
while read line
do
    if [[ $line =~ 'transparent' ]]
    then
        if [[ $line =~ '3306' ]]
        then
            echo "$line"
        elif [[ $line =~ '80' ]]
        then
            echo $line
            echo "${line%:*}:443 transparent ssl crt /etc/haproxy/ssl/openstack.pem"
            echo "redirect scheme https if !{ ssl_fc }"
        else
            echo "$line crt /etc/haproxy/ssl/openstack.pem"
        fi
    else
        echo "$line"
    fi
done < "${conf_file_path}/haproxy.cfg.org"
