 #!/bin/bash



#####################################################################################
## EXT SERVICES VM
#####################################################################################

echo ""
echo "Configuring EXT Services..."
echo ""

cd ansible
./configure_ext_services.sh
if [ $? -ne 0 ];
then
    cd ..
    exit -1
fi
cd ..



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
