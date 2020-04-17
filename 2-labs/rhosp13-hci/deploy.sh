#!/bin/bash
FAILED=0
sdate=$(date +%s)
currentdate=$(date)

# if [ $# -eq 0 ];
#     then echo "Illegal number of parameters, usage:"
#     echo ""
#     echo "$0 --env <environment> [--no-create]"
#     echo ""
#     exit -1
# fi

no_create=false
deploy_kvm=false


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
         *) echo >&2 "Invalid option $@"; echo "You can use:"; echo "    --no-create"; echo "    --deploy-kvm"; exit 1;;
    esac
 done



deploy_name=$(pwd | awk -F \/ '{print $NF}')

token=$(grep telegram_token 0-fill_in_secrets/secrets | awk -F \= '{print $2}')
chat_id=$(grep telegram_chat_id 0-fill_in_secrets/secrets | awk -F \= '{print $2}')

message="Lab *${deploy_name}* deploy has started"

./notify-telegram.sh --token $token --chat-id $chat_id --message "${message}"




echo ""
echo "Filling in secrets..."
echo ""
cd 0-fill_in_secrets/
./fill_in_secrets.sh
if [ $? -ne 0 ];
then
    FAILED=1
fi
 cd ..


if [ $deploy_kvm = true ]
then
echo ""
echo "Installing KVM server..."
echo ""
  cd 1-install_kvm/
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
  cd 2-create_vms/
  ./create_lab.sh
  if [ $? -ne 0 ];
  then
      FAILED=1
  fi
   cd ..
fi


sleep 15

echo ""
echo "Configuring VMs..."
echo ""
cd 3-configure_vms/
./configure_lab.sh
if [ $? -ne 0 ];
then
    FAILED=1
fi
 cd ..





###-----------------------------------------------------------------------------------------------------

# Send Messages


if [ $FAILED -eq 1 ];
then
    final_message="Lab $deploy_name deploy --- FAILED ---"
else
    final_message="Lab $deploy_name deploy SUCCESS"
fi



cdate=$(date +%s)
duration=$(( $(($cdate-$sdate)) / 60))
currentdate=$(date)

echo "******************************************************************"
echo "$final_message after $duration mins"
echo "******************************************************************"




./notify-telegram.sh --token $token --chat-id $chat_id --message "*${final_message}*\nDuration (mins): $duration"
