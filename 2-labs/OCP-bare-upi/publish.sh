#!/bin/bash

sudo iptables -A PREROUTING -t nat -i eno1 -p tcp --dport 443 -j DNAT --to 1.50.20.3:443
sudo iptables -A FORWARD -p tcp -d 1.50.20.3 --dport 443 -j ACCEPT

sudo iptables -A PREROUTING -t nat -i eno1 -p tcp --dport 80 -j DNAT --to 1.50.20.3:80
sudo iptables -A FORWARD -p tcp -d 1.50.20.3 --dport 80 -j ACCEPT

#sudo iptables -A PREROUTING -t nat -i eno1 -p tcp --dport 10022 -j DNAT --to 1.50.20.3:22
#sudo iptables -A FORWARD -p tcp -d 1.50.20.3 --dport 22 -j ACCEPT


sudo iptables -A PREROUTING -t nat -i eno1 -p tcp --dport 6443 -j DNAT --to 1.50.20.3:6443
sudo iptables -A FORWARD -p tcp -d 1.50.20.3 --dport 6443 -j ACCEPT
