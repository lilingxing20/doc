#!/usr/bin/env python
# -*- coding:utf-8 -*-

'''
Author      : lixx (https://github.com/lilingxing20)
Created Time: Wed 30 Dec 2020 08:09:03 PM CST
File Name   : hello_world_producer1.py
Description : 
'''

import pika,sys

#connect to the rabbitmq,use the default vhost
credentials = pika.PlainCredentials("tony","123456")
conn_params = pika.ConnectionParameters("172.30.126.51",
                                        credentials=credentials)
conn_broker = pika.BlockingConnection(conn_params)

#get a channel used to communicate with the rabbitmq
channel = conn_broker.channel()

#declare a exchange
channel.exchange_declare(exchange='hello-exchange',
                         type='direct',
                         passive=False,     #if the exchange already existes,report a error.It means we want to declare an exchange.
                         durable=True,      #durable the message
                         auto_delete=False) #if the last consumer is over,do not delete the exchange auto

#create a message
msg = sys.argv[1]
msg_props = pika.BasicProperties()
msg_props.content_type = "text/plain"
#publish the message
channel.basic_publish(body=msg,
                      exchange='hello-exchange',
                      properties=msg_props,
                      routing_key='hola')
