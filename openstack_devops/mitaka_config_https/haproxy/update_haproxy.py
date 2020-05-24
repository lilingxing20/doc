#!/usr/bin/env python
# coding=utf-8

'''
Author      : lixx (https://github.com/lilingxing20)
Created Time: Fri 19 Jan 2018 03:19:14 PM CST
File Name   : update_haproxy.py
Description : 
'''
file='haproxy.cfg.org'
f=open(file)
line = f.readline()
while line:
    if 'transparent' in line:
        if '3306' in line:
            print line,
        elif '80' in line:
            print line,
            print '%s:443 transparent ssl crt /etc/haproxy/ssl/openstack.pem' % line[:line.rfind(':')]
            print "  redirect scheme https if !{ ssl_fc }"
        else:
            print line.strip("\n"),"crt /etc/haproxy/ssl/openstack.pem"
    else:
            print line,
    line = f.readline()

