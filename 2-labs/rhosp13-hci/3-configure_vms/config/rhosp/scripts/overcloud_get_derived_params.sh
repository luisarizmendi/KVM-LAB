#!/bin/bash
export OS_CACERT=
source ~/stackrc

openstack overcloud deploy --templates --update-plan-only  \
       -n ~/templates/network_data.yaml \
       -r ~/templates/roles_data.yaml \
       -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
       -e /usr/share/openstack-tripleo-heat-templates/environments/network-environment.yaml \
       -e ~/templates/environments/40-network-override-environment.yaml \
       -e ~/templates/overcloud_images.yaml \
       -p /home/stack/plan-environment-derived-params.yaml \
       --environment-directory ~/templates/environments \
       --log-file overcloud_install.log
