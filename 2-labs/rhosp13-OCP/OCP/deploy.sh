#!/bin/bash

FAILED=0
sdate=$(date +%s)
currentdate=$(date)



deploy_name=$(pwd | awk -F \/ '{print $NF}')

token=$(grep telegram_token 0-fill_in_secrets/secrets | awk -F \= '{print $2}')
chat_id=$(grep telegram_chat_id 0-fill_in_secrets/secrets | awk -F \= '{print $2}')

message="Lab *${deploy_name}* deploy has started"

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
fi
 cd ..

echo "**** CREATING INFRA  ****"





echo "****  RUNNING THE OCP PRE-INSTALLATION  ****"


ansible-playbook -vv -i inventory 2-ocp_preinstall/0-prepare_installer_host/ocp-installer_host.yaml -e @vars.yaml -e @3-ocp_install/ocp-install-files/install-config.yaml
if [ $? -ne 0 ];
then
    FAILED=1
fi



ansible-playbook -vv -i inventory 2-ocp_preinstall/1-prepare_infra/prepare-osp.yaml -e @vars.yaml -e @3-ocp_install/ocp-install-files/install-config.yaml
if [ $? -ne 0 ];
then
    FAILED=1
fi



ansible-playbook -vv -i inventory 2-ocp_preinstall/2-ext_services_preinstall/ocp-ext-services-preinstall.yaml -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
fi



echo "****  RUNNING THE OCP INSTALLATION  ****"

ansible-playbook -vv -i inventory 3-ocp_install/ocp-install.yaml -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
fi



echo "****  RUNNING THE OCP POST-INSTALLATION  ****"


ansible-playbook -vv -i inventory 4-ocp_postinstall/0-infra_postinstall/postconfig-osp.yaml -e @vars.yaml -e @3-ocp_install/ocp-install-files/install-config.yaml
if [ $? -ne 0 ];
then
    FAILED=1
fi



# Reconfig DNS and add NFS storage


ansible-playbook -vv -i inventory 4-ocp_postinstall/1-ext_services_postinstall/ocp-ext-services-postinstall.yaml -e @vars.yaml -e @3-ocp_install/ocp-install-files/install-config.yaml
if [ $? -ne 0 ];
then
    FAILED=1
fi




# post kubernetes tasks

ansible-playbook -vv -i inventory 4-ocp_postinstall/2-ocp_postinstall/ocp-extra-steps.yaml -e @vars.yaml
if [ $? -ne 0 ];
then
    FAILED=1
fi



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
