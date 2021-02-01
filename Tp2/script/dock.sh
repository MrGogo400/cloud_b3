#!/bin/bash
#set -xv

usermod -aG docker vagrant
systemctl enable docker vagrant --now

if [[ $HOSTNAME == "node1" ]]; then 
    docker swarm init --advertise-addr 192.168.42.10
    docker swarm join-token manager |grep join > /vagrant/conf/token
else
    cat /vagrant/token |bash -
fi
