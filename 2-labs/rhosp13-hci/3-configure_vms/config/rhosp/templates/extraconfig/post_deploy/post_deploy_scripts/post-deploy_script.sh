#!/bin/bash
#
set -x

echo $(TZ=UTC date) >> /root/.timestamp_firstboot


my_node_role=$(cat /var/log/ospd/node_role)
my_node_index=$(cat /var/log/ospd/node_index)


#################################################################################### ENABLE  ####################################################################################

## BUG https://bugzilla.redhat.com/show_bug.cgi?id=1614268

####################################################################################  ####################################################################################
