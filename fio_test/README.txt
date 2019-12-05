# fio 磁盘性能测试
项目主页：https://github.com/axboe/fio
FIO输出结果详细解释可参见：https://tobert.github.io/post/2014-04-17-fio-output-explained.html
FIO是测试IOPS的非常好的工具，用来对硬件进行压力测试和验证。
注：fio用于测试磁盘性能，不是文件系统，测试之前需要先把要测试的磁盘卸载掉，测试完后需格式化一遍再挂载上去。


## 每个测试客户端运行 fio --server，如：
```
[root@fio-vm-c1-1 ~]# fio --server
fio: server listening on 0.0.0.0,8765
[root@fio-vm-c1-2 ~]# fio --server
fio: server listening on 0.0.0.0,8765
[root@fio-vm-c1-3 ~]# fio --server
fio: server listening on 0.0.0.0,8765
```

## 测试任务执行: 在其中一台执行
## 注意：在所有的测试虚拟机都生成/opt/fio_*.job文件，最终结果存储在执行任务的节点上，其他节点无内容。
### 单个测试任务
```
[root@fio-vm-c1-1 ~]fio --client hosts.fio.txt fio_write_1m.job --output=/opt/fio-write1m.txt --output-format=json
[root@fio-vm-c1-1 ~]fio --client hosts.fio.txt fio_read_1m.job --output=/opt/fio-read1m.txt --output-format=json
[root@fio-vm-c1-1 ~]fio --client hosts.fio.txt fio_randwrite_4k.job --output=/opt/fio-rand-write-4k.txt --output-format=json
[root@fio-vm-c1-1 ~]fio --client hosts.fio.txt fio_randread_4k.job --output=/opt/fio-rand-read-4k.txt --output-format=json
```

### 所有测试任务
```
[root@fio-vm-c1-1 ~]# fio --client hosts.fio.txt fio_all_task.job --output=/opt/fio-all-task.txt --output-format=json
```

## 运行python parsefio.py 输入json格式的结果文件分析结果：
```
[root@fio-vm-c1-1 ~]# python parse_fio_output.py /opt/fio-all-task.txt 
randread 4K test
randread_bw: 5.130859375 randread_iops 1314.180844 randread_clat_max 446.67057042 randread_clat_min 427.776611816
randwrite 4k test
randwrite_bw: 3.126953125 randwrite_iops 801.678469 randwrite_clat_max 739.171110628 randwrite_clat_min 698.584477426
read 1M test
read_bw: 408.228515625 read_iops 408.231778 read_clat_max 1438.70377424 read_clat_min 1342.80835433
write 1M test
write_bw: 259.5234375 write_iops 259.527264 write_clat_max: 2373.99017709 write_clat_min: 2113.62285849
```

