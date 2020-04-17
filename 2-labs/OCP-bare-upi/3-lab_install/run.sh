#!/bin/bash



#vms="ocp-bootstrap ocp-master0 ocp-master1 ocp-master2 ocp-worker0 ocp-worker1 ocp-worker2"
vms="ocp-bootstrap ocp-master0 ocp-master1 ocp-master2 ocp-worker0 ocp-worker1"


echo ""
echo "***********************************************************"
echo "Changing VMs boot order to boot from network and start them"
echo "***********************************************************"
echo ""

for vmname in $vms
do
  virsh destroy $vmname >/dev/null 2>&1
  virsh dumpxml $vmname > $vmname.xml
  sed -i "s#boot dev.*#boot dev\=\'network\'\/>#g" $vmname.xml
  virsh define --file $vmname.xml >/dev/null 2>&1
  virsh start  $vmname >/dev/null 2>&1
done


echo ""
echo "*************************************************************"
echo "Waiting to finish PXE boot and changing VMs boot order to boot from hd"
echo "*************************************************************"
echo ""

sleep 30

numfinished=0
numvms=0
for i in $vms; do numvms=$((numvms + 1)) ; done

while [ $numfinished != $numvms ]
do
  for vmname in $vms
  do
    lastentry=$(tail -n 1 /var/log/libvirt/qemu/$vmname.log)
    if [ "$(echo $lastentry | awk -F : '{print $1}')" == "inputs_channel_detach_tablet" ]; then
      virsh destroy $vmname >/dev/null 2>&1
      numfinished=$((numfinished + 1))
    fi
  done
done

sleep 5

for vmname in $vms
do
  sed -i "s#boot dev.*#boot dev\=\'hd\'\/>#g" $vmname.xml
  virsh define --file $vmname.xml >/dev/null 2>&1
  virsh start  $vmname >/dev/null 2>&1
  rm -rf $vmname.xml
done





echo ""
echo "********************************"
echo " Finishing installation ..."
echo "********************************"
echo ""
