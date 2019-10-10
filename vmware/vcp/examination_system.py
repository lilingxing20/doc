#!/usr/bin/env python3
# -*- coding:utf-8 -*-

'''
Author      : lixx (https://github.com/lilingxing20)
Created Time: Thu 08 Aug 2019 06:24:12 PM CST
File Name   : examination_system.py
Description : 
'''

import time
import random

score = 0                     # 记录分数，答对一题加10分，打错不扣分
have_done = []                # 定义一个list，主要放已经答过的题目，如果在该list中，则跳出这次循环开始下一次循环
correct = 0                   # 定义答对的题目的数量
fail = 0                      # 定义答错的题目的数量
temp_int = 0                  # 统计循环的次数，如果所有题目全部打完，则退出循环
question_id_list = []         # 定义一个list，该list主要是生成题目的序号
examination_questions = []    # 定义一个list，把试题文件每一行放在一个list中
question_list = []            # 定义一个list，把所有的题目按照“==”分割，每个题目作为一个该list的一个元素
exam_dict = {}                # 定义一个dict，格式化如下{序号：{题目：“题目内容”，选项：“选项内容”，答案：“答案内容”}}


# 读取试题文件 
#examination_file = './2v0-622-exam218'
examination_file = './2v0-21.19.96Q.2019'
with open(examination_file, "r", encoding="utf-8") as f:
    for line in f:
        if line.startswith('#'):
            continue
        examination_questions.append(line)
examination_str = "".join(examination_questions)

# 构建试题内容列表
question_list = examination_str.split("==")
total_num = len(question_list)
print("total_num: %d" % total_num)


# 生成题号
for i in range(total_num):
    question_id_list.append(i)

# 构建试卷字典
for _id in question_id_list:
    question_stem = question_list[_id].split("*")
    temp_dict = {}
    if len(question_stem) == 4:
        temp_dict[_id] = {"题目": question_stem[0], "选项": question_stem[1], 
                           "答案": question_stem[2], "解析": question_stem[3]}
    elif len(question_stem) == 3:
        temp_dict[_id] = {"题目": question_stem[0], "选项": question_stem[1], 
                           "答案": question_stem[2], "解析": ""}
    exam_dict.update(temp_dict)
 

# 开始考试 

## 顺序
# for idx in range(total_num-1):
#     #r = idx+1

## 随机
while True:
    if temp_int == total_num - 1:
        break
    r = random.randrange(0, total_num-1)
    r += 1

    #if r-1 not in [13, 14, 15, 18, 21, 23, 25, 26, 28, 30, 69, 94, 71, 78, 80, 81, 82, 84, 85, 86, 87, 36, 40, 44, 45, 46, 51, 49, 89, 90, 92, 93, 53, 54, 57, 58, 61, 63, 66, 67, 68]:
    #if r not in [46, 50, 54, 83, 86]:
    #if r not in [46, 21, 14, 72]:
    #    continue
 
    if r in have_done:
        continue
    else:
        g = "good"
        f = "failed"
        temp_int = temp_int + 1
        have_done.append(r)
        print("\n这是第 %d 道题." % temp_int)
        print(exam_dict[r]["题目"])
        print(exam_dict[r]["选项"])
        temp_option = input("你的选择:")
        option = temp_option.upper()
        if 'Q' in option:
            break
        s = set()
        b = set()
        for i in option:
            s.add(i)
        for c in exam_dict[r]["答案"].split(":")[-1].strip():
            if c == ',':
                continue
            b.add(c)
        if s == b:
            gg = g.center(100,"=")
            print(gg)
            correct = correct + 1
            print("你一共测试了 %d 道题，答对 %d, 答错 %d" % (temp_int, correct, fail))
            score = score + 10
 
        else:
            ff = f.center(100,"=")
            print(ff)
            fail = fail + 1
            time.sleep(3)
            print(b)
            print(exam_dict[r]["解析"])
            print("你一共测试了 %d 道题，答对 %d, 答错 %d" % (temp_int, correct, fail))
            time.sleep(5)

q = "end of examination"
qq = q.center(100,"=")
print("\n%s" % qq)
print("你的分数是: %d." % score)
print("你一共测试了 %d 道题，答对 %d, 答错 %d\n" % (temp_int, correct, fail))
exit()
