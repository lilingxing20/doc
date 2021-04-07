#!/usr/bin/env python
# -*- coding:utf-8 -*-

'''
Author      : lixx (https://github.com/lilingxing20)
Created Time: Wed 30 Dec 2020 08:44:48 PM CST
File Name   : rpc_server.py
Description : 
'''

import pika
 
credentials = pika.PlainCredentials("tony","123456")
conn_params = pika.ConnectionParameters("172.30.126.51",
                                        credentials=credentials)
connection = pika.BlockingConnection(conn_params)
 
channel = connection.channel()
 
channel.queue_declare(queue='rpc_queue')
 
def fib(n):
    if n == 0:
        return 0
    elif n == 1:
        return 1
    else:
        return fib(n-1) + fib(n-2)
 
def on_request(ch, method, props, body):
    n = int(body)
 
    print(" [.] fib(%s)" % n)
    response = fib(n)
 
    ch.basic_publish(exchange='',
                     routing_key=props.reply_to,
                     properties=pika.BasicProperties(correlation_id = \
                                                         props.correlation_id),
                     body=str(response))
    ch.basic_ack(delivery_tag = method.delivery_tag)
 
channel.basic_qos(prefetch_count=1)
channel.basic_consume(on_request, queue='rpc_queue')
 
print(" [x] Awaiting RPC requests")
channel.start_consuming()
