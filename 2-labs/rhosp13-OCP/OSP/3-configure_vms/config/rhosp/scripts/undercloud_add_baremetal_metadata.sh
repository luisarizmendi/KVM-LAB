#!/bin/bash
source stackrc
nodes=$(openstack baremetal node list -c UUID -f value)

#openstack baremetal node set --property capabilities='profile:control,boot_option:local' $(echo $nodes | awk '{print $1}')
openstack baremetal node set --property capabilities='node:controller-0,boot_option:local' $(echo $nodes | awk '{print $1}')
openstack baremetal node set --property root_device='{"name": "/dev/vda"}' $(echo $nodes | awk '{print $1}')
#openstack baremetal node set --property root_device='{"wwn": "0x50014ee25704434f"}' $(echo $nodes | awk '{print $1}')
#openstack baremetal node set --property root_device='{"serial": "644a84200ca381001cc2681b2564d1c9"}' $(echo $nodes | awk '{print $2}')


#openstack baremetal node set --property capabilities='profile:compute,boot_option:local' $(echo $nodes | awk '{print $4}')
openstack baremetal node set --property capabilities='node:computehci-0,boot_option:local' $(echo $nodes | awk '{print $2}')
openstack baremetal node set --property root_device='{"name": "/dev/vda"}' $(echo $nodes | awk '{print $2}')

#openstack baremetal node set --property capabilities='profile:compute,boot_option:local' $(echo $nodes | awk '{print $5}')
openstack baremetal node set --property capabilities='node:computehci-1,boot_option:local' $(echo $nodes | awk '{print $3}')
openstack baremetal node set --property root_device='{"name": "/dev/vda"}' $(echo $nodes | awk '{print $3}')

#openstack baremetal node set --property capabilities='profile:compute,boot_option:local' $(echo $nodes | awk '{print $6}')
openstack baremetal node set --property capabilities='node:computehci-2,boot_option:local' $(echo $nodes | awk '{print $4}')
openstack baremetal node set --property root_device='{"name": "/dev/vda"}' $(echo $nodes | awk '{print $4}')
