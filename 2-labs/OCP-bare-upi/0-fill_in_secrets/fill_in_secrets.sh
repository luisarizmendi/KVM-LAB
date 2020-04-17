#!/bin/bash


echo "Importing secrets (to maintain these templates without private info)"

secrets_file="secrets"


if [ ! -f $secrets_file ]; then
    echo ""
    echo "Secrets file not found: $secrets_file"
    echo ""
    exit -1
fi


vms_root_password=$(grep vms_root_password $secrets_file | awk -F \= '{print $2}')
sed -i "s/ root:.*/ root:$vms_root_password/g" ../1-create_infra/1-create_vms/terraform/cloud_init.cfg


rhel_reg_activation_key=$(grep rhel_reg_activation_key $secrets_file | awk -F \= '{print $2}')
sed -i "s/subs_activationkey:.*/subs_activationkey: $rhel_reg_activation_key/g" ../vars.yaml

rhel_reg_org=$(grep rhel_reg_org $secrets_file | awk -F \= '{print $2}')
sed -i "s/subs_orgid:.*/subs_orgid: $rhel_reg_org/g" ../vars.yaml

rhel_reg_pool=$(grep rhel_reg_pool $secrets_file | awk -F \= '{print $2}')
sed -i "s/subs_pool:.*/subs_pool: $rhel_reg_pool/g" ../vars.yaml



pullSecret=$(grep pullSecret $secrets_file | awk -F \pullSecret= '{print $2}')
sed -i "s#pullSecret:.*#pullSecret: \'$pullSecret\'#g" ../OCP-files/ocp-install-files/install-config.yaml
