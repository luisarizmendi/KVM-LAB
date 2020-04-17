#!/bin/bash

if [ $# -eq 0 ];
    then echo "Illegal number of parameters, usage:"
    echo ""
    echo "$0 --tfvars <file with terraform variables> "
    echo ""
    exit -1
fi


while [[ $# -gt 0 ]] && [[ ."$1" = .--* ]] ;
do
    opt="$1";
    shift;              #expose next argument
    case "$opt" in
        "--" ) break 2;;
        "--tfvars" )
           tfvars="$1"; shift;;
        *) echo >&2 "Invalid option: $@"; exit 1;;
   esac
done


  terraform init -input=false
  terraform destroy -force -auto-approve  -var-file=${tfvars}
  terraform plan -out=tfplan -input=false -var-file=${tfvars}
#  terraform plan -out=tfplan -input=false -var-file=${tfvars}
  terraform apply -input=false tfplan
