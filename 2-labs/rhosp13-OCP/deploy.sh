#!/bin/bash


echo ""
echo "Configuring OpenStack..."
echo ""

cd OSP/
./deploy.sh
cd ..



echo ""
echo "Configuring OpenShift..."
echo ""

cd OCP/
./deploy.sh
cd ..
