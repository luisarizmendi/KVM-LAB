 #!/bin/bash

KVM_URI=$(grep kvm_uri terraform/lab.tfvars    | awk -F = '{print $2}' | awk -F \" '{print $2}')
KVM_IP=$(echo $KVM_URI | awk -F \/\/ '{print $2}' | awk -F \/ '{print $1}' | awk -F @ '{print $2}')





################# CREATE VMS
echo "Creating VMs using Terraform..."
cd terraform
terraform destroy -force -auto-approve  -var-file=lab.tfvars
cd ..
