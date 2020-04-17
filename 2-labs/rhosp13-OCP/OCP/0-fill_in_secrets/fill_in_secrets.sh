#!/bin/bash


echo "Importing secrets (to maintain these templates without private info)"

secrets_file="secrets"


if [ ! -f $secrets_file ]; then
    echo ""
    echo "Secrets file not found: $secrets_file"
    echo ""
    exit -1
fi





pullSecret=$(grep pullSecret $secrets_file | awk -F \pullSecret= '{print $2}')
sed -i "s#pullSecret:.*#pullSecret: \'$pullSecret\'#g" ../3-ocp_install/ocp-install-files/install-config.yaml


# We use the director ssh key that is injected using ansible playbooks (ocp-install.yaml)
#sshKey=$(cat ~/.ssh/id_rsa.pub)
#sed -i "s#sshKey:.*#sshKey: \'$sshKey\'#g" ../3-ocp_install/ocp-install-files/install-config.yaml
