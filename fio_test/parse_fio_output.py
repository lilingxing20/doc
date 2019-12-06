#!/usr/bin/env python

import json
import os
import sys

#filename='./fio-rand-read-4k.txt'
filename=''
if len(sys.argv) > 1:
    filename=sys.argv[1]
else:
    filename = raw_input("please input your file:")
if not os.path.exists(filename):
    print "The file %s not exists !" % filename
    sys.exit(1)

allstr = ""
att_flat = False
with open(filename,'r') as f:
    for line in f.readlines():
        linestr = line.strip()
        if linestr == '{':
            att_flat = True
        if att_flat:
	    allstr += linestr

pythonobject = json.loads(allstr)
real = pythonobject['client_stats']

write_bw = 0
write_iops = 0
write_clat_list = []

randwrite_bw = 0
randwrite_iops = 0
randwrite_clat_list = []

read_bw = 0
read_iops = 0
read_clat_list = []

randread_bw = 0
randread_iops = 0
randread_clat_list = []

jobname_list = []

for l in real:
    jobname = l['jobname']
    jobname_list.append(jobname)

    if jobname == 'write_1M_test':
        write_bw += float(l['write']['bw'])
        write_iops += float(l['write']['iops'])
        write_clat_list.append(float(l['write']['clat_ns']['mean']))
  
        
    elif jobname == "randwrite_4K_test":
        randwrite_bw += float(l['write']['bw'])
        randwrite_iops += float(l['write']['iops'])
        randwrite_clat_list.append(float(l['write']['clat_ns']['mean']))

    elif jobname == "read_1M_test":
        read_bw += float(l['read']['bw'])
        read_iops += float(l['read']['iops'])
        read_clat_list.append(float(l['read']['clat_ns']['mean']))

    elif jobname == "randread_4K_test":
        randread_bw += float(l['read']['bw'])
        randread_iops += float(l['read']['iops'])
        randread_clat_list.append(float(l['read']['clat_ns']['mean']))

if "randread_4K_test" in jobname_list:
    print "randread 4K test"
    print "randread_bw:",randread_bw/1024,"randread_iops",randread_iops,"randread_clat_max",max(randread_clat_list)/1000000,"randread_clat_min",min(randread_clat_list)/1000000

if "randwrite_4K_test" in jobname_list:
    print "randwrite 4k test" 
    print "randwrite_bw:",randwrite_bw/1024,"randwrite_iops",randwrite_iops,"randwrite_clat_max",max(randwrite_clat_list)/1000000,"randwrite_clat_min",min(randwrite_clat_list)/1000000

if "read_1M_test" in jobname_list:
    print "read 1M test" 
    print "read_bw:",read_bw/1024,"read_iops",read_iops,"read_clat_max",max(read_clat_list)/1000000,"read_clat_min",min(read_clat_list)/1000000

if "write_1M_test" in jobname_list:
    print "write 1M test"
    print "write_bw:",write_bw/1024,"write_iops",write_iops,"write_clat_max:",max(write_clat_list)/1000000,"write_clat_min:",min(write_clat_list)/1000000

