#!/bin/bash
set -x
step_all=false
step_no_base=false
step_instance=true
step_volume=true
step_alarm=true
step_object=true
step_barbican=true
step_lbaas=false
step_autoscaling=true
step_nfv=false
step_baremetal=true
step_sahara=false
step_manila=true

while [[ $# -gt 0 ]] && [[ ."$1" = .--* ]] ;
do
    opt="$1";
    shift;              #expose next argument
    case "$opt" in
        "--" ) break 2;;
        "--help" )
           echo "Usage:"
           echo ""
           echo "$0 <parameter> <parameter> ..."
           echo ""
           echo "parameters:"
           echo "   --no-base (skips base resources creation)"
           echo "   --instance"
           echo "   --volume"
           echo "   --alarm"
           echo "   --object"
           echo "   --barbican"
           echo "   --lbaas"
           echo "   --autoscaling"
           echo "   --nfv"
           echo "   --baremetal"
           echo "   --manila"
           echo "   --sahara"
           echo ""
           exit 0 ;;
        "--no-base" )
           step_all=false; step_no_base=true;;
        "--instance" )
           step_all=false; step_instance=true;;
        "--volume" )
           step_all=false; step_volume=true;;
        "--alarm" )
           step_all=false; step_alarm=true;;
        "--object" )
           step_all=false; step_object=true;;
        "--barbican" )
           step_all=false; step_barbican=true;;
        "--lbaas" )
           step_all=false; step_lbaas=true;;
        "--autoscaling" )
           step_all=false; step_autoscaling=true;;
        "--nfv" )
           step_all=false; step_nfv=true;;
        "--baremetal" )
           step_all=false; step_baremetal=true;;
        "--manila" )
           step_all=false; step_manila=true;;
        "--sahara" )
           step_all=false; step_sahara=true;;
   esac
done



if [ $step_no_base = false ]
then
source /home/stack/stackrc
#computes=$(openstack server list -c Name -c Networks -f value | grep compute | awk -F "=" '{print $2}')
RCFILE="$(openstack stack list -c 'Stack Name' -f value)rc"
EXTVLANID=
NETEXT="10.2.1.0/24"
EXTGW="10.2.1.1"
EXTSTART="10.2.1.225"
EXTEND="10.2.1.250"



if [ ! -f /home/stack/$RCFILE ]; then
    echo "/home/stack/$RCFILE not found!"
    exit -1
fi




############### BUG
sed -i 's/\/\/v3/\/v3/g' /home/stack/$RCFILE



# Add CACERT
sudo cp /home/stack/scripts/cert_generate/OUTPUT/cacert.pem /etc/pki/ca-trust/source/anchors/
sudo update-ca-trust extract



source $RCFILE

echo "**********************************"
echo "CREATING OPENSTACK RESOURCES..."
echo "**********************************"

echo "Creating external and provider networks..."
openstack network create floating --external --provider-network-type flat --provider-physical-network datacentre
openstack subnet create floating --network floating --allocation-pool start=$EXTSTART,end=$EXTEND --gateway $EXTGW --subnet-range $NETEXT

#openstack network create provider --share  --provider-network-type vlan --provider-physical-network datacentre --provider-segment 244
#openstack network create provider --share  --provider-network-type flat --provider-physical-network provider
#openstack subnet create provider --network provider  --subnet-range 172.20.0.0/24

sleep 5




echo "Creating user redhat and project redhat..."
#openstack domain create --description "Domain using LDAPS" lablocal
domain=$(openstack domain list | grep lablocal  | awk '{print$2}')

openstack role add --domain $domain --user $(openstack user list --domain default | grep admin | awk '{print$2}') $(openstack role list | grep admin  | awk '{print$2}')
openstack project create --domain $domain redhat

## Speeds up LDAP integration
#for i in $controllers; do ssh-keygen -R $i ; ssh -o LogLevel=quiet -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null heat-admin@$i 'sudo systemctl restart httpd'; done
#sleep 15


# yum install -y openldap-clients
# ldapsearch -x -LLL -h 192.168.245.251 -D uid=admin,cn=users,cn=accounts,dc=osp,dc=lablocal -w redhatstack -b"dc=osp,dc=lablocal" -s sub "(objectClass=person)" "(memberOf=cn=openstack-users,ou=groups,dc=osp,dc=lablocal)"
user_redhat=$(openstack user show --domain $domain redhat -f value -c id)
openstack role add --project redhat --user $user_redhat admin
openstack role add --project admin --user $user_redhat admin




echo "Creating Red Hat RC file..."
mkdir -p /home/stack/rcfiles/
cp $RCFILE /home/stack/rcfiles/redhatrc
sed -i -- 's/OS_PROJECT_DOMAIN_NAME=Default/OS_PROJECT_DOMAIN_NAME=osp.lablocal/g' /home/stack/rcfiles/redhatrc
sed -i -- 's/OS_USER_DOMAIN_NAME=Default/OS_USER_DOMAIN_NAME=osp.lablocal/g' /home/stack/rcfiles/redhatrc
sed -i -- 's/OS_PROJECT_NAME=admin/OS_PROJECT_NAME=redhat/g' /home/stack/rcfiles/redhatrc
sed -i -- 's/OS_TENANT_NAME=admin/OS_TENANT_NAME=redhat/g' /home/stack/rcfiles/redhatrc
sed -i -- 's/OS_USERNAME=admin/OS_USERNAME=redhat/g' /home/stack/rcfiles/redhatrc
sed -i  '/OS_PASSWORD/d' /home/stack/rcfiles/redhatrc ;  echo export OS_PASSWORD=redhat >> /home/stack/rcfiles/redhatrc

source /home/stack/rcfiles/redhatrc





openstack quota set --cores 100 --instances 50 --ram 131072 --floating-ips 50  redhat



echo "Creating user data files..."




mkdir -p /home/stack/user-data-scripts

cat > /home/stack/user-data-scripts/userdata-enableroot << EOF
#cloud-config
# vim:syntax=yaml
debug: True
ssh_pwauth: True
disable_root: false
chpasswd:
  list: |
    root:redhat
  expire: false
runcmd:
 -  sed -i'.orig' -e's/without-password/yes/' /etc/ssh/sshd_config
 -  service sshd restart
EOF

cat > /home/stack/user-data-scripts/userdata-root_enable_eth1 << EOF
#cloud-config
debug: True
ssh_pwauth: True
disable_root: false
chpasswd:
  list: |
    root:redhat
  expire: false
write_files:
  - path: "/etc/sysconfig/network-scripts/ifcfg-eth1"
    permissions: "0644"
    owner: "root"
    content: |
      BOOTPROTO=dhcp
      PEERDNS=no
      DEVICE=eth1
      ONBOOT=yes
      TYPE=Ethernet
      USERCTL=no
runcmd:
 -  sed -i'.orig' -e's/without-password/yes/' /etc/ssh/sshd_config
 -  service sshd restart
 - 'systemctl restart network'
EOF


echo "Uploading images..."
mkdir -p /home/stack/user-images

curl -o /home/stack/user-images/cirros.qcow2 https://download.cirros-cloud.net/0.4.0/cirros-0.4.0-x86_64-disk.img
openstack image create cirros --file user-images/cirros.qcow2 --disk-format qcow2 --container-format bare --public
#rm /home/stack/user-images/cirros.qcow2

curl -o /home/stack/user-images/fedora30.qcow2 https://dl.fedoraproject.org/pub/fedora/linux/releases/30/Cloud/x86_64/images/Fedora-Cloud-Base-30-1.2.x86_64.qcow2
openstack image create fedora30 --file user-images/fedora30.qcow2 --disk-format qcow2 --container-format bare --public
#rm -f /home/stack/user-images/fedora30.qcow2



curl -o /home/stack/user-images/centos7.qcow2 https://cloud.centos.org/centos/7/images/CentOS-7-x86_64-GenericCloud.qcow2
openstack image create centos7 --file user-images/centos7.qcow2 --disk-format qcow2 --container-format bare --public
#rm -f /home/stack/user-images/centos7.qcow2


#sudo yum install -y rhel-guest-image-7.noarch
#openstack image create rhel7 --file /usr/share/rhel-guest-image-7/rhel-guest-image-7.2-20160302.0.x86_64.qcow2 --disk-format qcow2 --container-format bare




echo "Creating flavor..."
openstack flavor create --ram 512 --disk 1 --vcpus 1 m1.tiny
openstack flavor create --ram 2048 --disk 20 --vcpus 1 m1.small
openstack flavor create --ram 4096 --disk 40 --vcpus 2 m1.medium
openstack flavor create --ram 8192 --disk 80 --vcpus 4 m1.large
openstack flavor create --ram 16384 --disk 160 --vcpus 8 m1.xlarge


echo "Configuring Security Groups..."
openstack security group create allowall
openstack security group rule create allowall --protocol tcp --dst-port 1:65535
openstack security group rule create allowall --protocol udp --dst-port 1:65535
openstack security group rule create allowall --protocol icmp --dst-port -1



echo "Adding keypair..."
openstack keypair create --public-key ~/.ssh/id_rsa.pub undercloud-key

mkdir -p /home/stack/ssh-keys
echo "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxa7XWcn3SeUIP6ec72ZUA15KWzJ8Nd0zv2ixwXumYTpWuLVhAFIkQ5K92tqpr2qTlcQ+2+UiaD2qJtqHp3hvA64G2jSP9pU7FtdigAiTueV2tAHxWwrG67SCQphacPI6W+32M4VQ86J2Zt7dMyWMqEaHeK4c0ltJjEaWj1wg5nY6CKfvCR402rwBqwBv0kp5GXYITC4GTlF7LcxnFZpO8jhjGPrKOtdwnM11WhZHGaoQxXXUgpa/JWcmn4keNg+ZiHZIlPXR2X1p2jwJw9yNXlSzJaEhQ57ZiBfiQjd7r171eD8cgu8RPd4FoyP0oK/sYL852WwWqLJkVynUkhiUV" > /home/stack/ssh-keys/larizmen.pub
openstack keypair create --public-key /home/stack/ssh-keys/larizmen.pub larizmen-key


echo "Creating internal networks and router..."
openstack network create redhat-internal
openstack subnet create redhat-internal --network redhat-internal --dns-nameserver 8.8.8.8 --gateway 172.19.1.1 --subnet-range 172.19.1.0/24

openstack router create redhat-ext-router
openstack router set --external-gateway floating redhat-ext-router
openstack router add subnet redhat-ext-router redhat-internal

sleep 5



echo "Creating aggregates and affinity groups..."
#openstack aggregate create --zone AZ1  agg1
#openstack aggregate add host agg1 compute-0.localdomain
#openstack aggregate add host agg1 compute-1.localdomain
#openstack aggregate add host agg1 compute-2.localdomain

#openstack aggregate create --zone EPA-AZ1 --property epa=true epaagg1
#openstack aggregate add host epaagg1 nfvcompute-0.localdomain
#openstack aggregate add host epaagg1 nfvcompute-1.localdomain




ID_antiaff=$(openstack server group create --policy anti-affinity gr-antiaff -c id -f value)
ID_aff=$(openstack server group create --policy affinity gr-aff -c id -f value)

fi



if [ $step_all = true ] || [ $step_barbican = true ]
then

echo "**********************************"
echo "TESTING BARBICAN..."
echo "**********************************"
openstack role create creator
openstack role add --user redhat --project redhat creator
openstack role add --user redhat --project admin creator


openstack secret store --name testSecret --payload 'TestPayload'

openstack secret order create --name testSymmetricKey --algorithm aes --mode ctr --bit-length 256 --payload-content-type=application/octet-stream key

fi






if [ $step_all = true ] || [ $step_object = true ]
then
echo "**********************************"
echo "TESTING OBJECT STORAGE SERVICE..."
echo "**********************************"

openstack container create test-container

openstack object create --name test-file test-container /home/stack/scripts/overcloud_after_deploy_test.sh
fi


if [ $step_all = true ] || [ $step_instance = true ]
then
echo "**********************************"
echo "TESTING NEW INSTANCES..."
echo "**********************************"

echo "Creating instance and attaching floating IP..."
openstack server create  test --wait --user-data /home/stack/user-data-scripts/userdata-enableroot --key-name undercloud-key --security-group allowall  --flavor  m1.tiny --image cirros --network redhat-internal

echo "Attaching floating IP..."
LAST_FIP=$(openstack floating ip create --subnet floating floating -f value -c floating_ip_address )
openstack server add floating ip test $LAST_FIP

echo "Try to connect to $LAST_FIP"

#echo "Creating instance using provider network..."
#openstack server create  test-provider --user-data /home/stack/user-data-scripts/userdata-enableroot --key-name undercloud-key --security-group allowall  --flavor  m1.small --image fedora30  --nic net-id=$(openstack network list -f value | grep provider | awk '{print$1}')
fi


if [ $step_all = true ] || [ $step_volume = true ]
then
echo "**********************************"
echo "TESTING VOLUMES..."
echo "**********************************"

echo "Creating and attaching volume..."
openstack volume create --size 1 test
openstack server add volume test test

echo "Creating and attaching encrypted volume..."
openstack volume type create --encryption-provider nova.volume.encryptors.luks.LuksEncryptor --encryption-cipher aes-xts-plain64 --encryption-key-size 256 --encryption-control-location front-end LuksEncryptor-Template-256
openstack volume create --size 1 --type LuksEncryptor-Template-256 'Encrypted-Test-Volume'
openstack server add volume test Encrypted-Test-Volume




#echo "Creating instance  boot from volume"

#BOOTVOLID=$(openstack volume create --image $(openstack image list -f value | grep cirros | awk '{print $1}') --size 10 bootable_volume -c id -f value)

#openstack server create --wait --user-data /home/stack/user-data-scripts/userdata-enableroot --key-name undercloud-key --flavor m1.tiny  --security-group allowall --network redhat-internal \
#  --volume bootable_volume \
#  --block-device source=volume,id=$BOOTVOLID,dest=volume,size=10,shutdown=preserve,bootindex=0 \
#  test-bootvol


fi




if [ $step_all = true ] || [ $step_alarm = true ]
then

echo "**********************************"
echo "TESTING ALARM..."
echo "**********************************"



INSTANCE_ID=$(openstack server show test -c id -f value)
METRIC_ID=$(gnocchi resource show --type instance  $INSTANCE_ID -f json | grep cpu_util | awk -F '"' '{print $4}')


#aodh alarm create \
# --type gnocchi_aggregation_by_resources_threshold \
# --name cputhreshold-high \
# --description 'GnocchiAggregationByResourceThreshold' \
# --enabled True \
# --alarm-action 'log://' \
# --ok-action 'log://' \
# --insufficient-data-action 'log://' \
# --comparison-operator 'ge' \
# --evaluation-periods 2 \
# --threshold 50.0 \
# --granularity 60 \
# --aggregation-method mean \
# --metric cpu_util \
# --query '{"=": {"id": "'$INSTANCE_ID'"}}' \
# --resource-type instance


aodh alarm create \
  --name cpu_hi \
  --type gnocchi_resources_threshold \
  --description 'instance running hot' \
  --metric cpu_util \
  --threshold 70.0 \
  --comparison-operator gt \
  --aggregation-method mean \
  --granularity 60 \
  --evaluation-periods 2 \
  --alarm-action 'log://' \
  --resource-id $INSTANCE_ID \
  --resource-type instance


gnocchi measures aggregation --aggregation mean --granularity 60 --resource-type instance -m e7e8d3ba-9195-4851-a03f-4ca8cbcaea6d


ALARM_ID=$(aodh alarm show cputhreshold-high -f value -c alarm_id)
aodh alarm state get $ALARM_ID
aodh alarm-history show $ALARM_ID


# run 3 or 4 times this:  dd if=/dev/zero of=/dev/null &


fi





if [ $step_all = true ] || [ $step_manila = true ]
then
echo "**********************************"
echo "TESTING MANILA..."
echo "**********************************"


##################################################
########## TEST for MANILA CEPHFS driver
##################################################

#manila type-create cephfsnativetype false
#manila type-key cephfsnativetype set vendor_name=Ceph storage_protocol=CEPHFS

#manila create --share-type cephfsnativetype --name cephnativeshare1 cephfs 1

#FULL_PATH=$(manila share-export-location-list cephnativeshare1 | grep : | awk '{print $4}')

#CEPHFS_MONS=$(echo $FULL_PATH | awk -F :/ '{print $1}')
#CEPHFS_MOUNTPOINT="/$(echo $FULL_PATH | awk -F :/ '{print $2}')"

#manila access-allow cephnativeshare1 cephx redhat

#CEPHFS_KEY=$(manila access-list cephnativeshare1 | grep : | awk '{print $12}')

#cat > /home/stack/user-data-scripts/userdata-cephnativeshare1 << EOF
##cloud-config
#write_files:
# - content: |
#       [client.redhat]
#              key = $CEPHFS_KEY
#   path: /root/redhat.keyring
# - content: |
#       [client]
#              client quota = true
#              mon host = $CEPHFS_MONS
#   path: /root/ceph.conf
#packages:
# - ceph-fuse
#runcmd:
# - [ mkdir, -p, /shares ]
# - [ ceph-fuse, /shares, --id=redhat, --conf=/root/ceph.conf, --keyring=/root/redhat.keyring, --client-mountpoint=$CEPHFS_MOUNTPOINT ]
#EOF


#openstack server create  test-manila-1 --wait  --hint group=$ID_antiaff --user-data /home/stack/user-data-scripts/userdata-cephnativeshare1 --key-name undercloud-key --security-group allowall  --flavor  m1.small --image fedora30 --network redhat-internal


#LAST_FIP=$(openstack floating ip create --subnet floating floating -f value -c floating_ip_address )
#openstack server add floating ip test-manila-1  $LAST_FIP
#echo "Try to connect to $LAST_FIP"


##openstack server create  test-manila-2 --wait  --hint group=$ID_antiaff --user-data /home/stack/user-data-scripts/userdata-cephnativeshare1 --key-name undercloud-key --security-group allowall  --flavor  m1.small --image fedora30 --network redhat-internal

##LAST_FIP=$(openstack floating ip create --subnet floating floating -f value -c floating_ip_address )
##openstack server add floating ip test-manila-2  $LAST_FIP
##echo "Try to connect to $LAST_FIP"


########################################################################


##################################################
########## TEST for MANILA NFS driver
##################################################


openstack network create --provider-network-type flat --provider-physical-network provider --share shares
openstack subnet create --network shares --subnet-range 172.28.0.0/24 --ip-version 4 --allocation-pool start=172.28.0.21,end=172.28.0.200 --gateway none --dhcp shares


manila type-create cephfsnfstype false
manila type-key cephfsnfstype set vendor_name=Ceph storage_protocol=NFS

manila create --share-type cephfsnfstype --name cephnfsshare1 nfs 1


manila access-allow cephnfsshare1 ip 172.28.0.0/24


FULL_PATH=$(manila share-export-location-list cephnfsshare1 | grep : | awk '{print $4}')


cat > /home/stack/user-data-scripts/userdata-cephnfsshare1 << EOF
#cloud-config
debug: True
ssh_pwauth: True
disable_root: false
chpasswd:
  list: |
    root:redhat
  expire: false
write_files:
  - path: "/etc/sysconfig/network-scripts/ifcfg-eth1"
    permissions: "0644"
    owner: "root"
    content: |
      BOOTPROTO=dhcp
      PEERDNS=no
      DEVICE=eth1
      ONBOOT=yes
      TYPE=Ethernet
      USERCTL=no
packages:
 - nfs-utils
runcmd:
 -  sed -i'.orig' -e's/without-password/yes/' /etc/ssh/sshd_config
 -  service sshd restart
 - 'systemctl restart network'
 - 'mkdir -p /shares'
 - 'mount -vv -t nfs $FULL_PATH /shares'
EOF




# Security group to drop all incomming connections using shares network
openstack security group create no-ingress
openstack port create nfs-port0 --network shares --security-group no-ingress


openstack server create  test-manila-1 --wait  --hint group=$ID_antiaff --user-data /home/stack/user-data-scripts/userdata-cephnfsshare1 --key-name undercloud-key --security-group allowall  --flavor  m1.small --image fedora30 --network  redhat-internal --nic port-id=$(openstack port show nfs-port0 -c id -f value)


LAST_FIP=$(openstack floating ip create --subnet floating floating -f value -c floating_ip_address )
#openstack server add floating ip test-manila-1  $LAST_FIP
PORT_TO_FIP=$(openstack port list -c id -c "Fixed IP Addresses" -f value   | grep $(openstack server show test-manila-1 -f value -c addresses | awk -F = '{print $2}' | awk -F ';' '{print $1}') | awk '{print $1}')
openstack floating ip set --port $PORT_TO_FIP $LAST_FIP


echo "Try to connect to $LAST_FIP"






fi



if [ $step_all = true ] || [ $step_lbaas = true ]
then
echo "**********************************"
echo "TESTING LBaaS..."
echo "**********************************"

cat > /home/stack/user-data-scripts/web-server << EOF
#!/bin/bash
yum install -y nc
while true ; do nc -l -p 80 -c 'echo -e "HTTP/1.1 200 OK\n\n  \$(date) on host \$(hostname)"'; done
EOF

openstack server create  test-lb-member1 --wait --user-data /home/stack/user-data-scripts/web-server --key-name undercloud-key --security-group allowall  --flavor  m1.small --image fedora30 --network redhat-internal
openstack server create  test-lb-member2 --wait --user-data /home/stack/user-data-scripts/web-server --key-name undercloud-key --security-group allowall  --flavor  m1.small --image fedora30 --network redhat-internal

sleep 120

openstack loadbalancer create --name test-lb --vip-subnet-id redhat-internal
sleep 5
  echo "...waiting available status"
  while [ -z  "$(openstack loadbalancer list -f value | grep ACTIVE )" ]; do
        sleep 15
        echo -n "*"
  done
echo "Amphora is ACTIVE"
sleep 10



openstack loadbalancer listener create \
  --name test-lb-http \
  --protocol HTTP \
  --protocol-port 80 \
  test-lb


openstack loadbalancer pool create \
    --name test-lb-pool-http \
    --lb-algorithm ROUND_ROBIN \
    --listener test-lb-http \
    --protocol HTTP


openstack loadbalancer healthmonitor create  \
    --name test-HTTPmonitor-pool-http \
    --delay 5 \
    --max-retries 2 \
    --timeout 10 \
    --type HTTP \
    --url-path / \
    test-lb-pool-http



for instance in test-lb-member1 test-lb-member2
do
 openstack loadbalancer member create \
    --name $instance \
    --subnet-id redhat-internal \
    --address $(openstack server show $instance -c addresses -f value | awk -F '=' '{print $2}') \
    --protocol-port 80 \
    test-lb-pool-http
done


LB_VIP_PORT=$(openstack port list -f value | grep $( openstack loadbalancer list -c vip_address -f value) | awk '{print $1}')
openstack port set --security-group allowall $LB_VIP_PORT

LAST_FIP=$(openstack floating ip create --subnet floating floating -f value -c floating_ip_address )
openstack floating ip set --port $LB_VIP_PORT $LAST_FIP

echo "LB VIP: $LAST_FIP"
echo ""

fi




if [ $step_all = true ] || [ $step_autoscaling = true ]
then
echo "**********************************"
echo "TESTING LBaaS with AutoScaling ..."
echo "**********************************"

net_internal=$(openstack network list -f value | grep redhat-internal | awk '{print$1}')
subnet_internal=$(openstack subnet list -f value | grep redhat-internal | awk '{print$1}')
net_external=$(openstack network list -f value | grep floating | awk '{print$1}')

security_group=$(openstack security group show allowall -c id -f value)

cat > /home/stack/scripts/HEAT/autoscaling/environment-autoscaling.yaml << EOF
parameters:
  image: fedora30
  key: undercloud-key
  flavor: m1.small
  database_flavor: m1.small
  network: $net_internal
  subnet_id: $subnet_internal
  database_name: wordpress
  database_user: wordpress
  external_network_id: $net_external
  security_group_front: $security_group
  security_group_db: $security_group
EOF


openstack stack create --wait -e /home/stack/scripts/HEAT/autoscaling/environment-autoscaling.yaml -t /home/stack/scripts/HEAT/autoscaling/lb-wordpress.yaml test-autoscale


# Command to rise CPU: dd if=/dev/zero of=/dev/null
#     if multiple cores: fulload() { dd if=/dev/zero of=/dev/null | dd if=/dev/zero of=/dev/null | dd if=/dev/zero of=/dev/null | dd if=/dev/zero of=/dev/null & }; fulload; read; killall dd

# Stress has been installed so it could be also something like: "stress --cpu 2 --timeout 180"
fi



if [ $step_all = true ] || [ $step_nfv = true ]
then
echo "**********************************"
echo "TESTING EPA..."
echo "**********************************"

echo "Testing Hugepages and CPU pinning..."

openstack flavor create --ram 512 --disk 1 --vcpus 1 --property aggregate_instance_extra_specs: epa.tiny
nova flavor-key epa.tiny set hw:cpu_policy=dedicated
nova flavor-key epa.tiny set hw:cpu_thread_policy=isolate
nova flavor-key epa.tiny set hw:mem_page_size=1048576
nova flavor-key epa.tiny set hw:numa_mempolicy=strict

openstack flavor create --ram 2048 --disk 20 --vcpus 2 --property aggregate_instance_extra_specs: epa.small
nova flavor-key epa.small set hw:cpu_policy=dedicated
nova flavor-key epa.small set hw:cpu_thread_policy=isolate
nova flavor-key epa.small set hw:mem_page_size=1048576
nova flavor-key epa.small set hw:numa_mempolicy=strict

openstack flavor create --ram 4096 --disk 40 --vcpus 2  --property aggregate_instance_extra_specs: epa.medium
nova flavor-key epa.medium set hw:cpu_policy=dedicated
nova flavor-key epa.medium set hw:cpu_thread_policy=isolate
nova flavor-key epa.medium set hw:mem_page_size=1048576
nova flavor-key epa.medium set hw:numa_mempolicy=strict

openstack flavor create --ram 8192 --disk 80 --vcpus 4 --property aggregate_instance_extra_specs: epa.large
nova flavor-key epa.large set hw:cpu_policy=dedicated
nova flavor-key epa.large set hw:cpu_thread_policy=isolate
nova flavor-key epa.large set hw:mem_page_size=1048576
nova flavor-key epa.large set hw:numa_mempolicy=strict

openstack flavor create --ram 16384 --disk 160 --vcpus 8 --property aggregate_instance_extra_specs: epa.xlarge
nova flavor-key epa.xlarge set hw:cpu_policy=dedicated
nova flavor-key epa.xlarge set hw:cpu_thread_policy=isolate
nova flavor-key epa.xlarge set hw:mem_page_size=1048576
nova flavor-key epa.xlarge set hw:numa_mempolicy=strict

openstack server create  test-epa --key-name undercloud-key  --security-group allowall --flavor epa.small --image fedora30 --network redhat-internal

echo "Attaching floating IP..."
LAST_FIP=$(openstack floating ip create --subnet floating floating -f value -c floating_ip_address )
openstack server add floating ip test-epa $LAST_FIP



echo "Testing SRIOV and Passthrough ..."

openstack network create sriov --share  --provider-network-type vlan --provider-physical-network physnet_sriov --provider-segment 27
openstack subnet create sriov --no-dhcp  --network sriov  --subnet-range 172.22.26.128/25 --gateway 172.22.26.129 --allocation-pool start=172.22.26.130,end=172.22.26.254


neutron port-create sriov --binding:vnic-type direct --name vf1
neutron port-create sriov --binding:vnic-type direct-physical --name pf1



# !!!!!!!! "A custom image with Mellanox drivers is needed"
openstack image create centos7-sriov_mellanox --file /home/stack/user-images/centos7-sriov_mellanox.qcow2 --disk-format qcow2 --container-format bare



STATIC_IP=$(openstack port show pf1 -f value -c fixed_ips | awk -F \' '{print$2}')
STATIC_GW=$(openstack subnet show $(openstack port show pf1 -f value -c fixed_ips | awk -F \' '{print$4}') -c gateway_ip -f value)
STATIC_PREFIX=$(openstack subnet show $(openstack port show pf1 -f value -c fixed_ips | awk -F \' '{print$4}') -c cidr -f value | awk -F \/ '{print$2}')

cat > /home/stack/user-data-scripts/userdata-staticip-mellanox << EOF
#cloud-config
write_files:
  - path: "/etc/sysconfig/network-scripts/ifcfg-ens5"
    permissions: "0644"
    owner: "root"
    content: |
      TYPE=Ethernet
      BOOTPROTO=none
      ONBOOT=yes
write_files:
  - path: "/etc/sysconfig/network-scripts/ifcfg-ens5.27"
    permissions: "0644"
    owner: "root"
    content: |
      DEVICE=ens5.27
      BOOTPROTO=none
      IPADDR=$STATIC_IP
      PREFIX=$STATIC_PREFIX
      GATEWAY=$STATIC_GW
      ONBOOT=yes
      VLAN=yes
runcmd:
  - [ systemctl, restart, network.service ]
EOF

openstack server create test-passthrough --key-name undercloud-key --user-data /home/stack/user-data-scripts/userdata-staticip-mellanox --security-group allowall  --flavor epa.small --image centos7-sriov_mellanox --network redhat-internal --nic port-id=$(neutron port-list | grep pf1 | awk '{print $2}')



####
### NOTE THAT ENS4 INSTED THAN ENS5 IS USED SINCE IN THIS INSTANCE THERE IS NO ETH0 ENABLED
####

STATIC_IP=$(openstack port show vf1 -f value -c fixed_ips | awk -F \' '{print$2}')
STATIC_GW=$(openstack subnet show $(openstack port show vf1 -f value -c fixed_ips | awk -F \' '{print$4}') -c gateway_ip -f value)
STATIC_PREFIX=$(openstack subnet show $(openstack port show vf1 -f value -c fixed_ips | awk -F \' '{print$4}') -c cidr -f value | awk -F \/ '{print$2}')

cat > /home/stack/user-data-scripts/userdata-staticip-mellanox << EOF
#cloud-config
write_files:
  - path: "/etc/sysconfig/network-scripts/ifcfg-ens4"
    permissions: "0644"
    owner: "root"
    content: |
      BOOTPROTO=none
      IPADDR=$STATIC_IP
      PREFIX=$STATIC_PREFIX
      GATEWAY=$STATIC_GW
      DEVICE=ens4
      ONBOOT=yes
      TYPE=Ethernet
      USERCTL=no
runcmd:
  - [ systemctl, restart, network.service ]
EOF

openstack server create test-sriov --config-drive true --user-data /home/stack/user-data-scripts/userdata-staticip-mellanox  --key-name undercloud-key --flavor epa.small --image centos7-sriov_mellanox  --nic port-id=$(neutron port-list | grep vf1 | awk '{print $2}')




rm /home/stack/user-data-scripts/userdata-enableroot
rm /home/stack/user-data-scripts/userdata-staticip-mellanox

fi



if [ $step_all = true ] || [ $step_baremetal = true ]
then
echo "**********************************"
echo "TESTING BAREMETAL..."
echo "**********************************"

echo "Creating baremetal network"

openstack network create --provider-network-type flat --provider-physical-network baremetal --share baremetal
openstack subnet create --network baremetal --subnet-range 10.3.1.0/24 --ip-version 4 --gateway 10.3.1.1  --allocation-pool start=10.3.1.21,end=10.3.1.200  --dhcp baremetal

sleep 30
#openstack router add subnet redhat-ext-router baremetal


BAREMETAL_NETWORK_ID=$(openstack network show baremetal -f value -c id)

source /home/stack/stackrc
controllers=$(openstack server list -c Name -c Networks -f value | grep controller | awk -F "=" '{print $2}')
source /home/stack/rcfiles/redhatrc

for i in $controllers ;
do
  ssh-keygen -R $i
  ssh -o LogLevel=quiet -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null heat-admin@$i "sudo sed -i 's/cleaning_network=.*/cleaning_network=$BAREMETAL_NETWORK_ID/g' /var/lib/config-data/puppet-generated/ironic/etc/ironic/ironic.conf ";
  ssh -o LogLevel=quiet -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null heat-admin@$i "sudo sed -i 's/provisioning_network=.*/provisioning_network=$BAREMETAL_NETWORK_ID/g' /var/lib/config-data/puppet-generated/ironic/etc/ironic/ironic.conf ";
  ssh -o LogLevel=quiet -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null heat-admin@$i "sudo docker restart ironic_conductor";
done

sed -i '/IronicCleaningNetwork/d' /home/stack/templates/environments/50-baremetal-environment.yaml
echo "  IronicCleaningNetwork: $BAREMETAL_NETWORK_ID" >> /home/stack/templates/environments/50-baremetal-environment.yaml

sed -i '/IronicProvisioningNetwork/d' /home/stack/templates/environments/50-baremetal-environment.yaml
echo "  IronicProvisioningNetwork: $BAREMETAL_NETWORK_ID" >> /home/stack/templates/environments/50-baremetal-environment.yaml



echo "Creating aggregates..."

openstack flavor create --id auto --ram 2048  --vcpus 1 --disk 45 --property aggregate_instance_extra_specs:baremetal=true  --public baremetal

openstack flavor set m1.tiny --property aggregate_instance_extra_specs:baremetal=false
openstack flavor set m1.small --property aggregate_instance_extra_specs:baremetal=false
openstack flavor set m1.medium --property aggregate_instance_extra_specs:baremetal=false
openstack flavor set m1.large --property aggregate_instance_extra_specs:baremetal=false
openstack flavor set m1.xlarge --property aggregate_instance_extra_specs:baremetal=false



openstack aggregate create --property baremetal=true baremetal-hosts

openstack aggregate add host baremetal-hosts controller-0.localdomain
openstack aggregate add host baremetal-hosts controller-1.localdomain
openstack aggregate add host baremetal-hosts controller-2.localdomain



openstack aggregate create --property baremetal=false virtual-hosts

openstack aggregate add host virtual-hosts computehci-0.localdomain
openstack aggregate add host virtual-hosts computehci-1.localdomain
openstack aggregate add host virtual-hosts computehci-2.localdomain




echo "Creating deploy images..."


openstack image create \
  --container-format aki \
  --disk-format aki \
  --public \
  --file ~/images/ironic-python-agent.kernel bm-deploy-kernel

openstack image create \
  --container-format ari \
  --disk-format ari \
  --public \
  --file ~/images/ironic-python-agent.initramfs bm-deploy-ramdisk




echo "Importing baremetal nodes..."

cat > /tmp/add-baremetal-nodes.yaml << EOF
nodes:
    - name: D-0
      driver: pxe_ipmitool
      driver_info:
        ipmi_address: 192.168.24.1
        ipmi_port: 6260
        ipmi_username: SECRET
        ipmi_password: SECRET
      properties:
        cpus: 1
        cpu_arch: x86_64
        memory_mb: 4096
        local_gb: 45
        root_device:
            name: /dev/vda
      ports:
        - address: 52:54:00:19:10:be
    - name: D-1
      driver: pxe_ipmitool
      driver_info:
        ipmi_address: 192.168.24.1
        ipmi_port: 6261
        ipmi_username: SECRET
        ipmi_password: SECRET
      properties:
        cpus: 1
        cpu_arch: x86_64
        memory_mb: 4096
        local_gb: 45
        root_device:
            name: /dev/vda
      ports:
        - address: 52:54:00:35:93:89
EOF



openstack baremetal create /tmp/add-baremetal-nodes.yaml

BM_KERNEL=$(openstack image show bm-deploy-kernel -f value -c id)
BM_RAMDISK=$(openstack image show bm-deploy-ramdisk -f value -c id)

openstack baremetal node set D-0 \
  --driver-info deploy_kernel=$BM_KERNEL \
  --driver-info deploy_ramdisk=$BM_RAMDISK

  openstack baremetal node set D-1 \
    --driver-info deploy_kernel=$BM_KERNEL \
    --driver-info deploy_ramdisk=$BM_RAMDISK



openstack flavor set baremetal --property capabilities:boot_option="local"
openstack baremetal node set --property capabilities="boot_option:local" D-0
openstack baremetal node set --property capabilities="boot_option:local" D-1


#openstack baremetal node set --property root_device='{"wwn": "XXXXXXXXXX"}' E-1
#openstack baremetal node set --property root_device='{"wwn": "XXXXXXXXXX"}' E-2




openstack baremetal node manage --wait 0  D-0
openstack baremetal node manage --wait 0  D-1

openstack baremetal node provide --wait 0 D-0
openstack baremetal node provide --wait 0 D-1





echo "Creating user images..."

mkdir -p /home/stack/user-images/baremetal/partition
cp /home/stack/user-images/centos7.qcow2 /home/stack/user-images/baremetal/partition/centos7-baremetal.qcow2

cd /home/stack/user-images/baremetal/partition

export DIB_LOCAL_IMAGE=/home/stack/user-images/baremetal/partition/centos7-baremetal.qcow2
sudo  -E disk-image-create centos7 baremetal dhcp-all-interfaces grub2 -o centos7-image-partition


KERNEL_ID=$(openstack image create \
  --file /home/stack/user-images/baremetal/partition/centos7-image-partition.vmlinuz --public \
  --container-format aki --disk-format aki \
  -f value -c id centos7-image.vmlinuz)

RAMDISK_ID=$(openstack image create \
  --file  /home/stack/user-images/baremetal/partition/centos7-image-partition.initrd --public \
  --container-format ari --disk-format ari \
  -f value -c id centos7-image.initrd)

openstack image create \
  --file /home/stack/user-images/baremetal/partition/centos7-image-partition.qcow2   --public \
  --container-format bare \
  --disk-format qcow2 \
  --property kernel_id=$KERNEL_ID \
  --property ramdisk_id=$RAMDISK_ID \
  centos7-baremetal-partition




mkdir -p /home/stack/user-images/baremetal/whole
cp /home/stack/user-images/centos7.qcow2 /home/stack/user-images/baremetal/whole/centos7-baremetal.qcow2


cd /home/stack/user-images/baremetal/whole
  export DIB_LOCAL_IMAGE=/home/stack/user-images/baremetal/whole/centos7-baremetal.qcow2
  sudo -E disk-image-create centos7 vm dhcp-all-interfaces grub2 -o centos7-image-whole

openstack image create \
  --file /home/stack/user-images/baremetal/whole/centos7-image-whole.qcow2   --public \
  --container-format bare \
  --disk-format qcow2 \
  centos7-baremetal-whole


cd /home/stack/



echo "Launching baremetal node..."

openstack server create test-baremetal-partition --wait --user-data /home/stack/user-data-scripts/userdata-enableroot   --security-group allowall   --key-name undercloud-key  --network baremetal   --flavor baremetal   --image centos7-baremetal-partition

openstack server create test-baremetal-whole --wait --user-data /home/stack/user-data-scripts/userdata-enableroot   --security-group allowall   --key-name undercloud-key  --network baremetal   --flavor baremetal   --image centos7-baremetal-whole


fi








if [ $step_all = true ] || [ $step_sahara = true ]
then
  echo "**********************************"
  echo "TESTING DATA PROCESSING..."
  echo "**********************************"



echo "Creating images for DATA PROCESSING"

  mkdir -p /home/stack/user-images/sahara
  cp /home/stack/user-images/centos7.qcow2 /home/stack/user-images/sahara/sahara-hortonworks-2.5.qcow2
#  cp /usr/share/rhel-guest-image-7/rhel-guest-image-7.2-20160302.0.x86_64.qcow2 /home/stack/user-images/sahara/rhel7-sahara.qcow2

sudo yum install openstack-sahara-image-pack -y


cd /home/stack/user-images/sahara/
sahara-image-pack --image sahara-hortonworks-2.5.qcow2 ambari 2.5
cd /home/stack/


openstack image create sahara-hortonworks-2.5 --file /home/stack/user-images/sahara/sahara-hortonworks-2.5.qcow2 --disk-format qcow2 --container-format bare

sleep 60

# Register Image
echo "Registering Image"

openstack dataprocessing image register sahara-hortonworks-2.5 --username centos
openstack dataprocessing image tags add sahara-hortonworks-2.5 --tags ambari 2.5



echo "Configuring node group templates"

FLOATING_NET_ID=$(openstack network show floating -c id -f value)

openstack dataprocessing node group template create --autoconfig \
    --name hortonworks-nodegroup-master --plugin ambari  \
    --plugin-version 2.5 --processes  Ambari "MapReduce History Server" "Spark History Server" NameNode ResourceManager SecondaryNameNode "YARN Timeline Server" ZooKeeper "Kafka Broker" "Hive Metastore" HiveServer Oozie \
    --flavor m1.xlarge --auto-security-group --floating-ip-pool ${FLOATING_NET_ID}


openstack dataprocessing node group template create --autoconfig  \
    --name hortonworks-nodegroup-worker --plugin ambari \
    --plugin-version 2.5 --processes DataNode NodeManager \
    --flavor m1.medium --auto-security-group --floating-ip-pool ${FLOATING_NET_ID} \
    --volumes-per-node 2 --volumes-size 10




echo "Configuring cluster templates"

openstack dataprocessing cluster template create --autoconfig  \
    --name hortonworks-cluster-template \
    --node-groups hortonworks-nodegroup-master:1 hortonworks-nodegroup-worker:2

sleep 30

echo "Create cluster (NOTE: this step takes loooooooong........)"

openstack dataprocessing cluster create --wait --name test-cluster-1 \
    --cluster-template hortonworks-cluster-template --user-keypair undercloud-key \
    --neutron-network redhat-internal --image sahara-hortonworks-2.5


sleep 300







echo "Registering Data and run Jobs"

openstack container create test-sahara




# PIG

 curl -o /tmp/pig-input https://raw.githubusercontent.com/openstack/sahara-tests/master/sahara_tests/scenario/defaults/edp-examples/edp-pig/cleanup-string/data/input
 touch /tmp/pig-output

 openstack object create --name input-pig test-sahara /tmp/pig-input
 openstack object create --name output-pig test-sahara /tmp/pig-output


 openstack dataprocessing data source create --type swift --username redhat --password redhat \
  --url "swift://test-sahara/input-pig" input-pig

 openstack dataprocessing data source create --type swift --username redhat --password redhat \
  --url "swift://test-sahara/output-pig" output-pig


curl -o /tmp/example.pig https://raw.githubusercontent.com/openstack/sahara-tests/master/sahara_tests/scenario/defaults/edp-examples/edp-pig/cleanup-string/example.pig
curl -k -o /tmp/edp-pig-udf-stringcleaner.jar -H "Accept: application/zip"  https://raw.githubusercontent.com/openstack/sahara-tests/master/sahara_tests/scenario/defaults/edp-examples/edp-pig/cleanup-string/edp-pig-udf-stringcleaner.jar


openstack object create --name example.pig test-sahara /tmp/example.pig
openstack object create --name edp-pig-udf-stringcleaner.jar test-sahara /tmp/edp-pig-udf-stringcleaner.jar


openstack dataprocessing job binary create --url "swift://test-sahara/example.pig" \
  --username redhat --password redhat --description "example.pig binary example" --name example.pig

openstack dataprocessing job binary create --url "swift://test-sahara/edp-pig-udf-stringcleaner.jar" \
  --username redhat --password redhat --description "edp-pig-udf-stringcleaner.jar binary example" --name edp-pig-udf-stringcleaner.jar



openstack dataprocessing job template create --type Pig \
   --name pigsample --main example.pig --libs edp-pig-udf-stringcleaner.jar


openstack dataprocessing job execute --input input-pig --output output-pig \
  --job-template pigsample --cluster test-cluster-1





# Spark

cat > /tmp/input-spark << EOF
OpenStack is a free and open-source software platform for cloud computing, mostly deployed as infrastructure-as-a-service (IaaS), whereby virtual servers and other resources are made available to customers
EOF

touch /tmp/output-spark

openstack object create --name input-spark test-sahara /tmp/input-spark
openstack object create --name output-spark test-sahara /tmp/output-spark


 openstack dataprocessing data source create --type swift --username redhat --password redhat \
  --url "swift://test-sahara/input-spark" input-spark

 openstack dataprocessing data source create --type swift --username redhat --password redhat \
  --url "swift://test-sahara/output-spark" output-spark




curl -k -o /tmp/spark-wordcount.jar -H "Accept: application/zip"  https://raw.githubusercontent.com/openstack/sahara-tests/master/sahara_tests/scenario/defaults/edp-examples/edp-spark/spark-wordcount.jar

openstack object create --name spark-wordcount.jar test-sahara /tmp/spark-wordcount.jar

openstack dataprocessing job binary create --url "swift://test-sahara/spark-wordcount.jar" \
  --username redhat --password redhat --description "spark-wordcount.jar binary example" --name sparkexample.jar




openstack dataprocessing job template create --type Spark \
   --name sparkexamplejob --main sparkexample.jar

openstack dataprocessing job execute  \
   --job-template sparkexamplejob --cluster test-cluster-1 \
   --configs edp.java.main_class:sahara.edp.spark.SparkWordCount edp.spark.adapt_for_swift:true fs.swift.service.sahara.password:redhat fs.swift.service.sahara.username:redhat  --args  swift://test-sahara/input-spark swift://test-sahara/output-spark


fi

echo "DONE!"
