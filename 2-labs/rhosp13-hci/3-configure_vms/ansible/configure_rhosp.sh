#!/bin/bash




################# NODES PREDEPLOYMENT




ansible-playbook -vv -i inventory/inventory-director playbooks/node-predeploy.yaml -e @vars/director/node-predeploy_vars.yaml
if [ $? -ne 0 ];
then
    exit -1
fi






################# UNDERCLOUD CONFIGURATION


DIRECTOR_IP=$(cat inventory/inventory-director | grep -m1 host  | awk -F \= '{print $2}' | awk '{print $1}')
OSP_TEMPLATES_PATH='../config/rhosp/'


ssh-keygen -R ${DIRECTOR_IP}
scp -r -o StrictHostKeyChecking=no  $OSP_TEMPLATES_PATH/* stack@$DIRECTOR_IP:/home/stack/
if [ $? -ne 0 ];
then
    exit -1
fi


#ansible-playbook -vv  -i inventory/inventory-director playbooks/rhosp/undercloud_certs_install.yaml
#if [ $? -ne 0 ];
#then
#    exit -1
#fi

ansible-playbook -vv  -i inventory/inventory-director playbooks/rhosp/undercloud_install.yaml  -e @vars/director/rhosp_vars.yaml
if [ $? -ne 0 ];
then
    exit -1
fi



ansible-playbook -vv  -i inventory/inventory-director  playbooks/rhosp/vbmc_setup.yaml  -e @vars/director/vbmc-config_vars.yaml
if [ $? -ne 0 ];
then
    exit -1
fi
## You can check with:   ipmitool -I lanplus -U root -P {password} -H {YOUR DESIRED IP} -p {port} power status




################# OVERCLOUD CONFIGURATION


ansible-playbook -vv  -i  inventory/inventory-director playbooks/rhosp/overcloud_install.yaml
if [ $? -ne 0 ];
then
    exit -1
fi
