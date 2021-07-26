#!/bin/bash

yum install python2-virtualbmc

iptables -A IN_public_allow -p tcp -m tcp --dport 6230:6300 -m conntrack --ctstate NEW -j ACCEPT
iptables -A IN_public_allow -p udp -m udp --dport 6230:6300 -m conntrack --ctstate NEW -j ACCEPT
iptables -A IN_public_allow -p udp -m udp --dport 5900:6000 -m conntrack --ctstate NEW -j ACCEPT
iptables -A IN_public_allow -p tcp -m tcp --dport 5900:6000 -m conntrack --ctstate NEW -j ACCEPT
