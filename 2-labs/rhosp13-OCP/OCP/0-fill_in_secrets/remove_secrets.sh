#!/bin/bash


echo "Remove secrets (to maintain these templates without private info)"


# Remove ansible.log
find .. -name "ansible.log" -type f -delete





sed -i "s/pullSecret:.*/pullSecret: SECRET/g" ../3-ocp_install/ocp-install-files/install-config.yaml

sed -i "s/sshKey:.*/sshKey: SECRET/g" ../3-ocp_install/ocp-install-files/install-config.yaml
