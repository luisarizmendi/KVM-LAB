#!/bin/bash


################# NODES PREDEPLOYMENT


ansible-playbook -vv -i inventory/inventory-ext_services playbooks/node-predeploy.yaml -e @vars/ext-services/node-predeploy_vars.yaml
if [ $? -ne 0 ];
then
    exit -1
fi
################# NODES CONFIGURATION


ansible-playbook -i inventory/inventory-ext_services  -vv playbooks/ext-services/ext-nfs.yaml
if [ $? -ne 0 ];
then
    exit -1
fi


ansible-playbook -i inventory/inventory-ext_services  -vv playbooks/ext-services/ext-idm.yaml
if [ $? -ne 0 ];
then
    exit -1
fi
