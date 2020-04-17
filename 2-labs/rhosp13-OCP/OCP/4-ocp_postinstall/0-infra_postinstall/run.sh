#!/bin/bash
set -x
# install openstack cli if it's not there


floatingnetwork=$1
FIP=$2



source ocpuserrc



# FIX floating ip
openstack floating ip create  --floating-ip-address $FIP $floatingnetwork


PORT_FOR_FIP=$(openstack port list -c ID -c Name -f value | grep ingress | awk '{print $1}')


openstack floating ip set --port $PORT_FOR_FIP $FIP
