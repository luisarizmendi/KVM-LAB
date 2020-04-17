#!/bin/bash
export OS_CACERT=
source ~/stackrc



#echo "Adding Overcloud public VIP cacert ..."
### Add Overcloud CACERT
#sudo cp /home/stack/certs/overcloud/overcloud-cacert.pem /etc/pki/ca-trust/source/anchors/overcloud-cacert.pem
#sudo chown root:root /etc/pki/ca-trust/source/anchors/overcloud-cacert.pem
#sudo chmod 0644 /etc/pki/ca-trust/source/anchors/overcloud-cacert.pem
#sudo update-ca-trust extract


echo "Deploying ..."
#for i in $(openstack baremetal node list -c UUID -f value);do openstack baremetal node power off $i ; done

time openstack overcloud deploy --templates  \
       -n ~/templates/network_data.yaml \
       -r ~/templates/roles_data.yaml \
       -e /usr/share/openstack-tripleo-heat-templates/environments/network-isolation.yaml \
       -e /usr/share/openstack-tripleo-heat-templates/environments/network-environment.yaml \
       -e ~/templates/environments/40-network-override-environment.yaml \
       -e ~/templates/overcloud_images.yaml \
       --environment-directory ~/templates/environments \
       --stack rhosp \
       --log-file overcloud_install.log
