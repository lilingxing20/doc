#!/usr/bin/env python
# -*- coding:utf-8 -*-

'''
Author      : lixx (https://github.com/lilingxing20)
Created Time: Wed 30 Dec 2020 08:46:32 PM CST
File Name   : rpc_client.py
Description : 
'''
import pika
import uuid
 
class FibonacciRpcClient(object):
    def __init__(self):
        credentials = pika.PlainCredentials("tony","123456")
        conn_params = pika.ConnectionParameters("172.30.126.51",
                                                credentials=credentials)
        self.connection = pika.BlockingConnection(conn_params)
 
        self.channel = self.connection.channel()
 
        result = self.channel.queue_declare(exclusive=True)
        self.callback_queue = result.method.queue
 
        self.channel.basic_consume(self.on_response, no_ack=True,
                                   queue=self.callback_queue)
 
    def on_response(self, ch, method, props, body):
        if self.corr_id == props.correlation_id:
            self.response = body
 
    def call(self, n):
        self.response = None
        self.corr_id = str(uuid.uuid4())
        self.channel.basic_publish(exchange='',
                                   routing_key='rpc_queue',
                                   properties=pika.BasicProperties(
                                         reply_to = self.callback_queue,
                                         correlation_id = self.corr_id,
                                         ),
                                   body=str(n))
        while self.response is None:
            self.connection.process_data_events()
        return int(self.response)
 
fibonacci_rpc = FibonacciRpcClient()
 
print(" [x] Requesting fib(30)")
response = fibonacci_rpc.call(30)
print(" [.] Got %r" % response)
