#!/bin/bash

FAILED=0
sdate=$(date +%s)
currentdate=$(date)



deploy_name=$(pwd | awk -F \/ '{print $NF}')

token=$(grep telegram_token 0-fill_in_secrets/secrets | awk -F \= '{print $2}')
chat_id=$(grep telegram_chat_id 0-fill_in_secrets/secrets | awk -F \= '{print $2}')

message="Lab *${deploy_name}* deploy has started"

failed_step=""


./notify-telegram.sh --token $token --chat-id $chat_id --message "${message}"










echo ""
echo "Filling in secrets..."
echo ""
cd 0-fill_in_secrets/
chmod +x fill_in_secrets.sh
./fill_in_secrets.sh
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="filling in secrets"
fi
 cd ..





echo "**** CREATING INFRA  ****"

no_infra=false

 while [[ $# -gt 0 ]] && [[ ."$1" = .--* ]] ;
 do
     opt="$1";
     shift;              #expose next argument
     case "$opt" in
         "--" ) break 2;;
         "--no-infra" )
            no_infra="true";;
    esac
 done


if [ $no_infra = false ]
then
  cd 1-create_infra/
  ./run.sh
  if [ $? -ne 0 ];
  then
      FAILED=1
      failed_step="creating infra"
  fi
  cd ..
fi

echo "****  RUNNING THE LAB PRE-INSTALLATION  ****"


ansible-playbook -vv -i inventory 2-lab_preinstall/0-prepare_vms/node-predeploy.yaml -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="lab pre-install"
fi

ansible-playbook -vv -i inventory 2-lab_preinstall/0-prepare_vms/node-predeploy-nosubs.yaml -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="lab pre-install non-rhel"
fi

### HELPER #######################################################

ansible-playbook -vv -i inventory 2-lab_preinstall/2-ext_services_preinstall/dns/ocp-helper-dns.yaml -e @OCP-files/ocp-install-files/install-config.yaml  -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="helper dns configuration"
fi

ansible-playbook -vv -i inventory 2-lab_preinstall/2-ext_services_preinstall/dhcp/ocp-helper-dhcp.yaml -e @OCP-files/ocp-install-files/install-config.yaml  -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="helper dhcp configuration"
fi


ansible-playbook -vv -i inventory 2-lab_preinstall/2-ext_services_preinstall/haproxy/ocp-helper-haproxy.yaml -e @OCP-files/ocp-install-files/install-config.yaml  -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="helper haproxy configuration"
fi

ansible-playbook -vv -i inventory 2-lab_preinstall/2-ext_services_preinstall/http/ocp-helper-http.yaml -e @OCP-files/ocp-install-files/install-config.yaml  -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="helper http server configuration"
fi

ansible-playbook -vv -i inventory 2-lab_preinstall/2-ext_services_preinstall/pxe/ocp-helper-pxe.yaml -e @OCP-files/ocp-install-files/install-config.yaml  -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="helper pxe configuration"
fi

ansible-playbook -vv -i inventory 2-lab_preinstall/2-ext_services_preinstall/nfs/ocp-helper-nfs.yaml -e @OCP-files/ocp-install-files/install-config.yaml  -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="helper nfs configuration"
fi

### ####### #######################################################





# Prepare installer ###########

ansible-playbook -vv -i inventory 2-lab_preinstall/3-ocp_preinstall/ocp-installer_host.yaml -e @OCP-files/ocp-install-files/install-config.yaml -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="installer preparation"
fi



# Prepare files in the helper server ###########

ansible-playbook -vv -i inventory 2-lab_preinstall/3-ocp_preinstall/ocp-upload-image-files.yaml -e @OCP-files/ocp-install-files/install-config.yaml -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="helper files preparation"
fi





echo "****  RUNNING THE LAB INSTALLATION  ****"

cd 3-lab_install/
chmod +x run.sh
./run.sh
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="installing OCP"
fi
 cd ..



echo "****  RUNNING THE LAB POST-INSTALLATION  ****"

ansible-playbook -vv -i inventory 4-lab_postinstall/1-ocp_postinstall/ocp-installer-postinstall.yaml -e @OCP-files/ocp-install-files/install-config.yaml  -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="installer post-install"
fi

ansible-playbook -vv -i inventory 4-lab_postinstall/2-ext_services_postinstall/ocp-helper-postinstall.yaml -e @OCP-files/ocp-install-files/install-config.yaml  -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="helper post-install"
fi


ansible-playbook -vv -i inventory 4-lab_postinstall/3-ocp-extra/ocp-extra-steps.yaml -e @OCP-files/ocp-install-files/install-config.yaml  -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
    failed_step="extra steps"
fi




###-----------------------------------------------------------------------------------------------------

# Send Messages


if [ $FAILED -eq 1 ];
then
    final_message="Lab $deploy_name deploy --- FAILED --- while $failed_step"
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
