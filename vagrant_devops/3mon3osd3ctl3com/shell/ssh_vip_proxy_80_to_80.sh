#!/bin/bash

ssh -o User=vagrant -o Port=22 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -o PasswordAuthentication=no -o ForwardX11=no -o IdentitiesOnly=yes -o IdentityFile=/root/.vagrant.d/insecure_private_key -L 172.16.134.33:80:192.168.41.66:80 -N 192.168.41.66 &

firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload
