 #!/bin/bash



#####################################################################################
## RHOSP
#####################################################################################

echo ""
echo "Configuring RHOSP..."
echo ""

cd ansible

./configure_rhosp.sh
if [ $? -ne 0 ];
then
    cd ..
    exit -1
fi




cd ..
