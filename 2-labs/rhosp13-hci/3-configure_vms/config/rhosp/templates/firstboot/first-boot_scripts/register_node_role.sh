#!/bin/bash
set -x
# Globals

LOG_DIR="/var/log/ospd"
my_hostname=$(hostname -s)
my_node_role_file="/var/log/ospd/node_role"
my_node_role=""
my_node_index_file="/var/log/ospd/node_index"
my_node_index=""

CTRL_FORMAT="$(echo _CTRL_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"
CMPT_FORMAT="$(echo _CMPT_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"
CHCI_FORMAT="$(echo _CHCI_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"
CEPH_FORMAT="$(echo _CEPH_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"
SWFT_FORMAT="$(echo _SWFT_FORMAT_|sed -e 's/\%index\%//g' -e 's/\%stackname\%//g')"

/usr/bin/mkdir -p ${LOG_DIR}
/usr/bin/chown root:root ${LOG_DIR}
/usr/bin/chmod 750 ${LOG_DIR}


# Determine node type
case ${my_hostname} in
  *${CTRL_FORMAT}*)
    echo "Controller node detected..."
    my_node_role="CTRL"
    my_node_index=$(echo "${my_hostname}"| sed -e "s/${CTRL_FORMAT}//")
    ;;
  *${CMPT_FORMAT}*)
    echo "Compute node detected..."
    my_node_role="CMPT"
    my_node_index=$(echo "${my_hostname}"| sed -e "s/${CMPT_FORMAT}//")
    ;;
  *${CHCI_FORMAT}*)
    echo "ComputeHCI node detected..."
    my_node_role="CHCI"
    my_node_index=$(echo "${my_hostname}"| sed -e "s/${CHCI_FORMAT}//")
    ;;
  *${CEPH_FORMAT}*)
    echo "Ceph node detected..."
    my_node_role="CEPH"
    my_node_index=$(echo "${my_hostname}"| sed -e "s/${CEPH_FORMAT}//")
    ;;
  *${SWFT_FORMAT}*)
    echo "Swift node detected..."
    my_node_role="SWFT"
    my_node_index=$(echo "${my_hostname}"| sed -e "s/${SWFT_FORMAT}//")
    ;;
esac

# Save the detected node role..
echo "${my_node_role}" > ${my_node_role_file}
echo "${my_node_index}" > ${my_node_index_file}
