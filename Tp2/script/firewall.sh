#!/bin/bash

echo "Préparation du firewall"
firewall-cmd --add-port=8888/tcp --permanent
firewall-cmd --add-port=2377/tcp --permanent
firewall-cmd --add-port=4789/udp --permanent
firewall-cmd --add-port=7946/udp --permanent
firewall-cmd --add-port=7946/tcp --permanent
firewall-cmd --add-port=5000/tcp --permanent
firewall-cmd --add-port=9000/tcp --permanent
firewall-cmd --permanent --zone=public --add-service=http
firewall-cmd --permanent --zone=public --add-service=https
firewall-cmd --reload
echo "Configuration Firewall Terminé"
