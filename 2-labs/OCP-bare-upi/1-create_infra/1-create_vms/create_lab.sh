 #!/bin/bash

KVM_URI=$(grep kvm_uri terraform/lab.tfvars    | awk -F = '{print $2}' | awk -F \" '{print $2}')
KVM_IP=$(echo $KVM_URI | awk -F \/\/ '{print $2}' | awk -F \/ '{print $1}' | awk -F @ '{print $2}')





################# CREATE VMS
echo "Creating VMs using Terraform..."
cd terraform
./deploy_terraform_lab.sh --tfvars lab.tfvars
if [ $? -ne 0 ];
then
    cd ..
    exit -1
fi
cd ..


#ssh -t -o StrictHostKeyChecking=no  root@${KVM_IP} "systemctl restart network"
