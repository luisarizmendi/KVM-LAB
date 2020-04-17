#!/bin/bash


echo "Importing secrets (to maintain these templates without private info)"

secrets_file="secrets"


if [ ! -f $secrets_file ]; then
    echo ""
    echo "Secrets file not found: $secrets_file"
    echo ""
    exit -1
fi





## 1-install_kvm





## 2-create_vms


kvm_ip=$(grep kvm_ip $secrets_file | awk -F \= '{print $2}')
sed -i "s/qemu+ssh:\/\/root@.*/qemu+ssh:\/\/root@${kvm_ip}\/system\"/g" ../2-create_vms/terraform/lab.tfvars


vms_root_password=$(grep vms_root_password $secrets_file | awk -F \= '{print $2}')
sed -i "s/ root:.*/ root:$vms_root_password/g" ../2-create_vms/terraform/cloud_init.cfg


## 3-configure_vms


rhel_reg_activation_key=$(grep rhel_reg_activation_key $secrets_file | awk -F \= '{print $2}')
sed -i "s/subs_activationkey:.*/subs_activationkey: $rhel_reg_activation_key/g" ../3-configure_vms/ansible/vars/ext-services/node-predeploy_vars.yaml
sed -i "s/subs_activationkey:.*/subs_activationkey: $rhel_reg_activation_key/g" ../3-configure_vms/ansible/vars/director/node-predeploy_vars.yaml
sed -i "s/rhel_reg_activation_key:.*/rhel_reg_activation_key: \"$rhel_reg_activation_key\"/g" ../3-configure_vms/config/rhosp/templates/environments/20-environment-rhel-registration.yaml

rhel_reg_org=$(grep rhel_reg_org $secrets_file | awk -F \= '{print $2}')
sed -i "s/subs_orgid:.*/subs_orgid: $rhel_reg_org/g" ../3-configure_vms/ansible/vars/ext-services/node-predeploy_vars.yaml
sed -i "s/subs_orgid:.*/subs_orgid: $rhel_reg_org/g" ../3-configure_vms/ansible/vars/director/node-predeploy_vars.yaml
sed -i "s/rhel_reg_org:.*/rhel_reg_org: \"$rhel_reg_org\"/g" ../3-configure_vms/config/rhosp/templates/environments/20-environment-rhel-registration.yaml

rhel_reg_pool=$(grep rhel_reg_pool $secrets_file | awk -F \= '{print $2}')
sed -i "s/subs_pool:.*/subs_pool: $rhel_reg_pool/g" ../3-configure_vms/ansible/vars/ext-services/node-predeploy_vars.yaml
sed -i "s/subs_pool:.*/subs_pool: $rhel_reg_pool/g" ../3-configure_vms/ansible/vars/director/node-predeploy_vars.yaml
sed -i "s/rhel_reg_pool_id:.*/rhel_reg_pool_id: \"$rhel_reg_pool\"/g" ../3-configure_vms/config/rhosp/templates/environments/20-environment-rhel-registration.yaml



ipmi_user=$(grep ipmi_user $secrets_file | awk -F \= '{print $2}')
ipmi_password=$(grep ipmi_password $secrets_file | awk -F \= '{print $2}')

sed -i "s/pm_user\".*/pm_user\": \"$ipmi_user\",/g" ../3-configure_vms/config/rhosp/instackenv.json
sed -i "s/pm_password\".*/pm_password\": \"$ipmi_password\",/g" ../3-configure_vms/config/rhosp/instackenv.json

sed -i "s/ipmi_username:.*/ipmi_username: $ipmi_user/g" ../3-configure_vms/config/rhosp/scripts/overcloud_after_deploy_test.sh
sed -i "s/ipmi_password:.*/ipmi_password: $ipmi_password/g" ../3-configure_vms/config/rhosp/scripts/overcloud_after_deploy_test.sh

sed -i "s/login:.*/login: $ipmi_user/g" ../3-configure_vms/config/rhosp/templates/environments/98-fencing.yaml
sed -i "s/passwd:.*/passwd: $ipmi_password/g" ../3-configure_vms/config/rhosp/templates/environments/98-fencing.yaml

sed -i "s/vbmc_username:.*/vbmc_username: $ipmi_user/g" ../3-configure_vms/ansible/vars/director/vbmc-config_vars.yaml
sed -i "s/vbmc_password:.*/vbmc_password: $ipmi_password/g" ../3-configure_vms/ansible/vars/director/vbmc-config_vars.yaml



kvm_ip=$(grep kvm_ip $secrets_file | awk -F \= '{print $2}')
sed -i "s/libvirt_server:.*/libvirt_server: ${kvm_ip}/g" ../3-configure_vms/ansible/vars/director/vbmc-config_vars.yaml
