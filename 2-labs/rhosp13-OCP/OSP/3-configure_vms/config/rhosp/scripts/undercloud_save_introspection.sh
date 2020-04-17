#!/bin/bash
source stackrc
#nodes=$(openstack baremetal node list -c UUID -f value)
nodes=$(openstack baremetal node list -c Name -f value)


mkdir /home/stack/introspection_data

for i in $nodes; do openstack baremetal introspection data save $i | jq '.' > /home/stack/introspection_data/$i ; done
