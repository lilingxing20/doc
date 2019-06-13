#!/usr/bin/env python
# -*- coding:utf-8 -*-

'''
https://my.oschina.net/diluga/blog/744283
'''
import json
from collections import OrderedDict
import csv
import subprocess

def get_pg_dump():
    cmd = "ceph pg dump --format=json"
    out = subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE)
    result = out.stdout.readlines()[1].split('\n')[0]
    return result

csv_file = './demo.csv' #生成的csv文件路径

pg_data = json.loads(get_pg_dump())
pg_dict = {}
osd_pg_dict = {}

for i in pg_data:
    for j in  pg_data['pg_stats']:
        pg_dict[j['pgid']] = j['up']

pool_pg_total = {}
osd_pg_num_dict = {}
tmp_pool_list = {}
tmp_osd_list = {}
start_osd = 0
start_pool_id = 0
all_result = {}

for i in pg_dict:
    pool_id =  int(i.split('.')[0])
    for osd_id in pg_dict[i]:
        tmp_pool_list[pool_id] = pool_id
        tmp_osd_list[osd_id] = osd_id

num_pool = max(tmp_pool_list.iterkeys(), key=lambda k: tmp_pool_list[k]) + 1
num_osd = max(tmp_osd_list.iterkeys(), key=lambda k: tmp_osd_list[k]) + 1
pool_totol_pg = [0] * num_pool
max_osd_list = [0] * num_pool
min_osd_list = [999] * num_pool
max_osdid_list = ['No_OSD'] * num_pool
min_osdid_list = ['No_OSD'] * num_pool
ave_osd_list = [0] * num_pool
ave_osd_list_result = [0] * num_pool
min_osd_per_list = [0] * num_pool
max_osd_per_list = [0] * num_pool

for i in range(0,num_osd):
    keyname = str(i)
    all_result[keyname] = [0] * num_pool

for i in pg_dict:
    pool_id = int(i.split('.')[0])
    for osd_id in pg_dict[i]:
        tmp_keyname = str(osd_id)
        tmp_list =  all_result[tmp_keyname]
        tmp_list[pool_id] = tmp_list[pool_id] +1

for i in all_result:
    tmp_num = 0
    for j in all_result[i]:
        if j < min_osd_list[tmp_num] and j != 0:
            min_osd_list[tmp_num] = j
            min_osdid_list[tmp_num] = i
        if j > max_osd_list[tmp_num]:
            max_osd_list[tmp_num] = j
            max_osdid_list[tmp_num] = i
        if j != 0:
            ave_osd_list[tmp_num] = ave_osd_list[tmp_num] + 1
        pool_totol_pg[tmp_num] = pool_totol_pg[tmp_num] + j
        tmp_num = tmp_num + 1

for i in range(0,len(ave_osd_list)):
    if ave_osd_list[i] != 0:
        ave_osd_list_result[i] = pool_totol_pg[i]/ave_osd_list[i]

all_result =  OrderedDict(sorted(all_result.items(), key=lambda t: int(t[0])))

for i in range(0,num_pool):
    if max_osd_list[i] != 0:
        max_osd_per_list[i] = round(100*(max_osd_list[i]-ave_osd_list_result[i])/float(ave_osd_list_result[i]),2)

for i in range(0, num_pool):
    if min_osd_list[i] != 999:
        min_osd_per_list[i] = round(100 * (min_osd_list[i] - ave_osd_list_result[i])/float(ave_osd_list_result[i]),2)

with open(csv_file, 'w') as csvfile:
    pool_list = []
    for i in range(0,num_pool):
        pool_list.append('pool-'+str(i))
    fieldnames = ['osd_name'] + pool_list + ['total']
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    for i in all_result:
        tmp_dict = {'osd_name': i,'total':sum(all_result[i])}
        tmp_num = 0
        for j in all_result[i]:
            keyname = 'pool-' + str(tmp_num)
            tmp_num = tmp_num + 1
            tmp_dict[keyname] = j
        writer.writerow(tmp_dict)
    fieldnames = ['SUM'] + pool_totol_pg + [sum(pool_totol_pg)]
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    fieldnames = ['AVE'] + ave_osd_list_result + [sum(ave_osd_list_result)]
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    fieldnames = ['MAX'] + max_osd_list + [sum(max_osd_list)]
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    fieldnames = ['MAX-OSD-ID'] + max_osdid_list
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    fieldnames = ['MAX-PER'] + max_osd_per_list + [sum(max_osd_per_list)]
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    fieldnames = ['MIN'] + min_osd_list + [sum(min_osd_list)]
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    fieldnames = ['MIN-OSD-ID'] + min_osdid_list
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()
    fieldnames = ['MIN-PER'] + min_osd_per_list + [sum(min_osd_per_list)]
    writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
    writer.writeheader()

print '---------------------------------------------------------------------------'
for i in  all_result:
    print i,all_result[i],sum(all_result[i])
print '---------------------------------------------------------------------------'
print 'SUM',pool_totol_pg
print 'MAX',max_osd_list
print 'MIN-OSD-ID',max_osdid_list
print 'MIN',min_osd_list
print 'MIN-OSD-ID',min_osdid_list
print 'AVE',ave_osd_list_result
print 'MIN-PER',min_osd_per_list
print 'MAX-PER',max_osd_per_list

