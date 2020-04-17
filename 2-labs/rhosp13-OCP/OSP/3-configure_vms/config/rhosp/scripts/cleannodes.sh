#!/bin/bash
# is auto cleaning enabled in ironic?
AUTO_CLEANING=1

if [ $# -eq 0 ]; then
    echo "USAGE $0 [pattern] cleans all nodes matching the pattern (e.g. compute, controller)"
    exit 1
fi

source ~/stackrc
echo "Cleaning nodes matching $1"
openstack baremetal node list -f value -c Name | grep $1 > /tmp/nodes

i=0
for NODE in $(cat /tmp/nodes); do
  i=$(($i+1))
  openstack baremetal node manage $NODE
  if [[ $AUTO_CLEANING -eq 0 ]]; then
     openstack baremetal node clean $NODE --clean-steps '[{"interface": "deploy", "step": "erase_devices_metadata"}]'
  fi
  openstack baremetal node provide $NODE
done

echo "$i node(s) match $1"
 
