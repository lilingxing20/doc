#!/bin/bash

# 参考地址：http://www.zphj1987.com/2015/10/04/%E6%9F%A5%E8%AF%A2osd%E4%B8%8A%E7%9A%84pg%E6%95%B0/
# awk圣经：The AWK Programming Language
# http://pan.baidu.com/s/1gdwbF71

#
## 语法的解释
#
#     BEGIN{ IGNORECASE=1 }
# IGNORECASE 非零开启忽略大小写匹配
#
#     /^pg_stat/ { col=1; while($col!="up") {col++}; }
# 匹配 pg dump 输出结果里面 pg_stat 字段开头的行，计算 up 字段所在列
# 
#     /^[0-9a-f]+.[0-9a-f]+/ { match($0,/^[0-9a-f]+/); pool_id=substr($0, RSTART, RLENGTH); poollist[pool_id]=0;
# 匹配pg号（如: 1.17a），使用自带的match函数做字符串的过滤统计，匹配.号前面的存储池ID，并得到 RSTART, RLENGTH 值，这个是取到前面的存储池ID字符串的开始位置和长度，使用 substr 函数，就可以得到 pool_id，poollist[pool_id]=0，是将数组poollist中下标为pool_id的元素的值置为0
# 
#     up=$(col+1); RSTART=0; RLENGTH=0; delete osds; i=0; while(match(up,/[0-9]+/)>0) { osds[++i]=substr(up,RSTART,RLENGTH); up = substr(up, RSTART+RLENGTH) }
# 首先获取up列的值（如:[8,2,5]），然后将match函数默认使用的变量(RSTART,RLENGTH)置0，清空osds数组，定义osds数组起始下标0，最后将osd编号一个个输入到osds的数组当中去
# 
#     for(i in osds) { array[osds[i],pool_id]++; osdlist[osds[i]]; }
# 将osds数组中的值输入到数组当中去，并且记录成列表osdlist，最后记录所有osd id的数组；二维数组array[osd[i],pool_id]记录所有osd和pool的关系
# 
#     printf("\n");
# 打印换行
#
#     printf("pool :\t"); for (i in poollist) printf("%s\t",i); printf("| SUM \n");
# 打印 osd pool_id 编号
# 
#     for (i in poollist) printf("-----"); printf("--------\n");
# 根据osd pool的长度打印分割符: "----"
# 
#     for (i in osdlist) { printf("osd.%i\t", i); sum=0;
# 打印 osd id 编号
# 
#     for (j in poollist) { printf("%i\t", array[i,j]); sum+=array[i,j]; poollist[j]+=array[i,j] }; printf("| %i\n", sum) }
# 打印对应的 osd 的 pg 数目，并做求和的统计pool的pg数目
# 
#     for (i in poollist) printf("----"); printf("--------\n");
# 根据osd pool的长度打印分割符: "----"
# 
#     printf("SUM :\t"); for (i in poollist) printf("%s\t",poollist[i]); printf("|\n");
# 打印新的poollist里面的求和的值
# 
# 修改版本里面用到的函数
# 
#     slen1=asorti(osdlist,newosdlist)
# 这个是将数组里面的下标进行排序，这里是对osd和poollist的编号进行排序 slen1是拿到数组的长度，使用for进行遍历输出
# 



# 查询osd上的pg数
function get_pg_num_per_osd_v1 {
awk '
 BEGIN { IGNORECASE=1 }
 /^pg_stat/ { col=1; while($col!="up") {col++};}
 /^[0-9a-f]+\.[0-9a-f]+/ { match($0,/^[0-9a-f]+/); pool_id=substr($0, RSTART, RLENGTH); poollist[pool_id]=0;
 up=$(col+1); i=0; RSTART=0; RLENGTH=0; delete osds; while(match(up,/[0-9]+/)>0) { osds[++i]=substr(up,RSTART,RLENGTH); up = substr(up, RSTART+RLENGTH) }
 for(i in osds) {array[osds[i],pool_id]++; osdlist[osds[i]];}
}
END {
 printf("\n");
 printf("pool :\t"); for (i in poollist) printf("%s\t",i); printf("| SUM \n");
 for (i in poollist) printf("--------"); printf("----------------\n");
 for (i in osdlist) { printf("osd.%i\t", i); sum=0;
 for (j in poollist) { printf("%i\t", array[i,j]); sum+=array[i,j]; poollist[j]+=array[i,j] }; printf("| %i\n",sum) }
 for (i in poollist) printf("--------"); printf("----------------\n");
 printf("SUM :\t"); for (i in poollist) printf("%s\t",poollist[i]); printf("|\n");
}'
}

########################################
#             运行结果示例             #
########################################
#
# pool :  4   5   6   1   2   3   | SUM 
# ----------------------------------------------------------------
# osd.26  23  5   8   36  18  15  | 105
# osd.17  27  6   11  39  19  18  | 120
# osd.18  48  14  13  38  30  21  | 164
# osd.6   55  16  13  48  23  23  | 178
# osd.7   31  15  6   30  19  22  | 123
# osd.9   61  13  14  45  24  27  | 184
# osd.21  35  3   6   37  17  10  | 108
# osd.0   48  11  15  58  24  25  | 181
# osd.23  27  12  5   25  13  12  | 94
# osd.24  52  12  13  48  18  26  | 169
# osd.15  61  10  11  56  31  27  | 196
# osd.25  22  4   7   27  10  13  | 83
# osd.16  22  7   6   25  10  17  | 87
# ----------------------------------------------------------------
# SUM :   512 128 128 512 256 256 |



# 查询osd上的pg数
# 包含osd pool的排序，包含osd的排序
function get_pg_num_per_osd_v2 {
awk '
 BEGIN { IGNORECASE=1 }
 /^pg_stat/ { col=1; while($col!="up") {col++}; }
 /^[0-9a-f]+\.[0-9a-f]+/ { match($0,/^[0-9a-f]+/); pool_id=substr($0, RSTART, RLENGTH); poollist[pool_id]=0;
 up=$(col+1); i=0; RSTART=0; RLENGTH=0; delete osds; while(match(up,/[0-9]+/)>0) { osds[++i]=substr(up,RSTART,RLENGTH); up = substr(up, RSTART+RLENGTH) }
 for(i in osds) {array[osds[i],pool_id]++; osdlist[osds[i]];}
}
END {
 printf("\n");
 slen=asorti(poollist,newpoollist);
 printf("pool :\t");for (i=1;i<=slen;i++) {printf("%s\t", newpoollist[i])}; printf("| SUM \n");
 for (i in poollist) printf("--------"); printf("----------------\n");
 slen1=asorti(osdlist,newosdlist)
 delete poollist;
 for (i=1;i<=slen1;i++) { printf("osd.%i\t", newosdlist[i]); sum=0; 
 for (j=1;j<=slen;j++)  { printf("%i\t", array[newosdlist[i],newpoollist[j]]); sum+=array[newosdlist[i],newpoollist[j]]; poollist[j]+=array[newosdlist[i],newpoollist[j]] }; printf("| %i\n",sum)
} 
for (i in poollist) printf("--------"); printf("----------------\n");
 printf("SUM :\t"); for (i=1;i<=slen;i++) printf("%s\t",poollist[i]); printf("|\n");
}'
}

########################################
#             运行结果示例             #
########################################
#
# pool :  1   2   3   4   5   6   | SUM 
# ----------------------------------------------------------------
# osd.0   58  24  25  48  11  15  | 181
# osd.15  56  31  27  61  10  11  | 196
# osd.16  25  10  17  22  7   6   | 87
# osd.17  39  19  18  27  6   11  | 120
# osd.18  38  30  21  48  14  13  | 164
# osd.21  37  17  10  35  3   6   | 108
# osd.23  25  13  12  27  12  5   | 94
# osd.24  48  18  26  52  12  13  | 169
# osd.25  27  10  13  22  4   7   | 83
# osd.26  36  18  15  23  5   8   | 105
# osd.6   48  23  23  55  16  13  | 178
# osd.7   30  19  22  31  15  6   | 123
# osd.9   45  24  27  61  13  14  | 184
# ----------------------------------------------------------------
# SUM :   512 256 256 512 128 128 |



# 查询osd上的pg数
# 包含osd pool的排序，包含osd的排序
# 输出平均pg数目，输出最大的osd编号，输出超过平均值的百分比
function get_pg_num_per_osd_v3 {
awk '
 BEGIN { IGNORECASE=1 }
 /^pg_stat/ { col=1; while($col!="up") {col++};}
 /^[0-9a-f]+\.[0-9a-f]+/ { match($0,/^[0-9a-f]+/); pool_id=substr($0, RSTART, RLENGTH); poollist[pool_id]=0;
 up=$(col+1); i=0; RSTART=0; RLENGTH=0; delete osds; while(match(up,/[0-9]+/)>0) { osds[++i]=substr(up,RSTART,RLENGTH); up = substr(up, RSTART+RLENGTH) }
 for(i in osds) {array[osds[i],pool_id]++; osdlist[osds[i]];}
}
END {
 printf("\n");
 slen=asorti(poollist,newpoollist);
 printf("pool :\t");for (i=1;i<=slen;i++) {printf("%s\t", newpoollist[i])}; printf("| SUM \n");
 for (i in poollist) printf("--------"); printf("----------------\n");
 slen1=asorti(osdlist,newosdlist)
 delete poollist;
 for (i=1;i<=slen1;i++) { printf("osd.%i\t", newosdlist[i]); sum=0; 
 for (j=1;j<=slen;j++)  { printf("%i\t", array[newosdlist[i],newpoollist[j]]); sum+=array[newosdlist[i],newpoollist[j]]; poollist[j]+=array[newosdlist[i],newpoollist[j]];if(array[newosdlist[i],newpoollist[j]] != 0){poolhasid[j]+=1 };if(array[newosdlist[i],newpoollist[j]]>maxpoolosd[j]){maxpoolosd[j]=array[newosdlist[i],newpoollist[j]];maxosdid[j]=newosdlist[i]}}; printf("| %i\n",sum)} 
for (i in poollist) printf("--------"); printf("----------------\n");
 printf("SUM :\t"); for (i=1;i<=slen;i++) printf("%s\t",poollist[i]); printf("|\n");
 printf("AVE :\t"); for (i=1;i<=slen;i++) printf("%d\t",poollist[i]/poolhasid[i]); printf("|\n");
 printf("max :\t"); for (i=1;i<=slen;i++) printf("%s\t",maxpoolosd[i]); printf("|\n");
 printf("osdid :\t"); for (i=1;i<=slen;i++) printf("osd.%s\t",maxosdid[i]); printf("|\n");
 printf("per:\t"); for (i=1;i<=slen;i++) printf("%.1f%\t",100*(maxpoolosd[i]-poollist[i]/poolhasid[i])/(poollist[i]/poolhasid[i])); printf("|\n");
}'
}

########################################
#             运行结果示例             #
########################################
#
# pool :  1   2   3   4   5   6   | SUM 
# ----------------------------------------------------------------
# osd.0   58  24  25  48  11  15  | 181
# osd.15  56  31  27  61  10  11  | 196
# osd.16  25  10  17  22  7   6   | 87
# osd.17  39  19  18  27  6   11  | 120
# osd.18  38  30  21  48  14  13  | 164
# osd.21  37  17  10  35  3   6   | 108
# osd.23  25  13  12  27  12  5   | 94
# osd.24  48  18  26  52  12  13  | 169
# osd.25  27  10  13  22  4   7   | 83
# osd.26  36  18  15  23  5   8   | 105
# osd.6   48  23  23  55  16  13  | 178
# osd.7   30  19  22  31  15  6   | 123
# osd.9   45  24  27  61  13  14  | 184
# ----------------------------------------------------------------
# SUM :   512 256 256 512 128 128 |
# AVE :   39  19  19  39  9   9   |
# max :   58  31  27  61  16  15  |
# osdid : osd.0   osd.15  osd.15  osd.15  osd.6   osd.0   |
# per:    47.3%   57.4%   37.1%   54.9%   62.5%   52.3%   |



cat pg_dump.txt | get_pg_num_per_osd_v1
cat pg_dump.txt | get_pg_num_per_osd_v2
cat pg_dump.txt | get_pg_num_per_osd_v3
# ceph pg dump | get_pg_num_per_osd_v1
# ceph pg dump | get_pg_num_per_osd_v2
# ceph pg dump | get_pg_num_per_osd_v3

