#!/bin/bash


no_create=false
deploy_kvm=false
destroy=false

 while [[ $# -gt 0 ]] && [[ ."$1" = .--* ]] ;
 do
     opt="$1";
     shift;              #expose next argument
     case "$opt" in
         "--" ) break 2;;
         "--no-create" )
            no_create="true";;
         "--deploy-kvm" )
            deploy_kvm="true";;
         "--destroy" )
            destroy="true";;
         *) echo >&2 "Invalid option $@"; echo "You can use:"; echo "    --no-create"; echo "    --deploy-kvm"; exit 1;;
    esac
 done




if [ $destroy = true ]
then
echo ""
echo "DESTROY VMS..."
echo ""
  cd 1-create_vms/
  ./delete_lab.sh
  if [ $? -ne 0 ];
  then
      FAILED=1
      exit -1
  fi
   cd ..
   exit 0
fi




if [ $deploy_kvm = true ]
then
echo ""
echo "Installing KVM server..."
echo ""
  cd 0-deploy_kvm/
  ./deploy_kvm.sh
  if [ $? -ne 0 ];
  then
      FAILED=1
  fi
   cd ..
fi



if [ $no_create = false ]
then
echo ""
echo "Creating VMs..."
echo ""
  cd 1-create_vms/
  ./create_lab.sh
  if [ $? -ne 0 ];
  then
      FAILED=1
  fi
   cd ..
fi



sleep 15
