#!/bin/bash


echo "Remove secrets (to maintain these templates without private info)"


# Remove ansible.log
find .. -name "ansible.log" -type f -delete




sed -i "s/ root:.*/ root:SECRET/g" ../1-create_infra/1-create_vms/terraform/cloud_init.cfg


sed -i "s/subs_activationkey:.*/subs_activationkey: SECRET/g" ../vars.yaml

sed -i "s/subs_orgid:.*/subs_orgid: SECRET/g" ../vars.yaml

sed -i "s/subs_pool:.*/subs_pool: SECRET/g" ../vars.yaml


sed -i "s#pullSecret:.*#pullSecret: \'SECRET\'#g" ../OCP-files/ocp-install-files/install-config.yaml
