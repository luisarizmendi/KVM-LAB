#!/bin/bash

pwd_src=$(pwd)

cd ../../../1-kvm-lab-setup/


./deploy.sh


cd $pwd_src

sleep 60
ansible-playbook download-image.yaml --extra-vars "image_name=CentOS-7-x86_64-GenericCloud.qcow2 image_url=https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2"
