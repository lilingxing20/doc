#!/usr/bin/env python
# -*- coding:utf-8 -*-

'''
Author      : lixx (https://github.com/lilingxing20)
Created Time: Wed 30 Dec 2020 08:12:36 PM CST
File Name   : hello_world_consumer.py
Description : 
'''
import pika

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

#declare a queue
channel.queue_declare(queue="hello-queue")

#bind queue to an exchange
channel.queue_bind(queue='hello-queue',
                   exchange='hello-exchange',
                   routing_key='hola')

#define the consumer method to consumer message from a queue
def msg_consumer(channel,method,header,body):
    channel.basic_ack(delivery_tag=method.delivery_tag)
    if body.decode("ascii") == "quit":
        channel.basic_cancel(consumer_tag='hello-consumer')
        channel.stop_consuming()
    else:
        print(body)
    return
#subscribe message
channel.basic_consume(msg_consumer,
                      queue='hello-queue',
                      consumer_tag='hello-consumer')
#begin loop until a quit message is sent
channel.start_consuming()
