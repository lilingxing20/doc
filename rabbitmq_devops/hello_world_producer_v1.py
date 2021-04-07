#!/usr/bin/env python
# -*- coding:utf-8 -*-

'''
Author      : lixx (https://github.com/lilingxing20)
Created Time: Wed 30 Dec 2020 08:09:03 PM CST
File Name   : hello_world_producer1.py
Description : 
'''

import pika,sys
from pika import spec

#connect to the rabbitmq,use the default vhost
credentials = pika.PlainCredentials("tony","123456")
conn_params = pika.ConnectionParameters("172.30.126.51",
                                        credentials=credentials)
conn_broker = pika.BlockingConnection(conn_params)

#get a channel used to communicate with the rabbitmq
channel = conn_broker.channel()

def confirm_handler(frame):
    if type(frame.method) == specConfirm.SelectOk:
        print("Channel in 'confirm' mode.")
    elif type(frame.method) == spec.Basic.Nack:
        if frame.method.delivery_tag in msg_ids:
            print("Message lost!")
    elif type(frame.method) == spec.Basic.Ack:
        if frame.method.delivery_tag in msg_ids:
            print("Confirm received!")
            msg_ids.remove(frame.method.delivery_tag)
channel.confirm_delivery(callback=confirm_handler)

#create a message
msg = sys.argv[1]
msg_props = pika.BasicProperties()
msg_props.content_type = "text/plain"
msg_ids = []
#publish the message
channel.basic_publish(body=msg,
                      exchange='hello-exchange',
                      properties=msg_props,
                      routing_key='hola')
msg_ids.append(len(msg_ids) + 1)
channel.close()
