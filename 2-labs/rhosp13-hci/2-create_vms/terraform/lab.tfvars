
#########################################################################################
# GENERAL
#
kvm_uri = "qemu+ssh://root@SECRET/system"
#kvm_uri = "qemu:///system"
kvm_pool-VMs = "vms"
kvm_pool-bases = "bases"


#########################################################################################
# Network
#
networks = [
     {
       name = "External_mgmt"
       cidr = "192.168.245.0/24"
       mode = "route"
       bridge = "virbr-rhosp-0"
       domain = "lablocal"
     },
     {
       name = "Provisioning"
       cidr = "10.0.1.0/24"
       mode = "none"
       bridge = "virbr-rhosp-1"
       domain = "lablocal"
     },
     {
       name = "Control_Group"
       cidr = "10.1.1.0/24"
       mode = "route"
       bridge = "virbr-rhosp-2"
       domain = "lablocal"
     },
     {
       name = "Data_Group"
       cidr = "10.2.1.0/24"
       mode = "route"
       bridge = "virbr-rhosp-3"
       domain = "lablocal"
     },
    {
      name = "Baremetal"
      cidr = "10.3.1.0/24"
      mode = "route"
      bridge = "virbr-rhosp-4"
      domain = "lablocal"
    },
    {
      name = "other"
      cidr = "172.20.0.0/24"
      mode = "route"
      bridge = "virbr-rhosp-5"
      domain = "lablocal"
    },
]


#########################################################################################
# Servers
#

#### With OS, 2 Networks (0 and 1) and 2 data disks
servers_type_1 = [
  {
    name = "director"
    running = "true"
    baseimage = "rhel-server-7.6-x86_64-kvm.qcow2"
    rootdisk = "1073741824"
    memory = "16384"
    vcpus = "6"
    mgmt_ip = "192.168.245.13"
    rootdisk = 107374182400
    datadisk-0 = 107374182400
  },
  {
    name = "extservices"
    running = "true"
    baseimage = "rhel-server-7.6-x86_64-kvm.qcow2"
    rootdisk = "1073741824"
    memory = "2048"
    vcpus = "1"
    mgmt_ip = "192.168.245.251"
    rootdisk = 107374182400
    datadisk-0 = 1
  },
]


#### Without OS, 6 Networks (0-5) and 3 data disks
servers_type_2 = [
  {
    name = "A-0"
    running = "false"
    rootdisk = "1073741824"
    memory = "20480"
    vcpus = "4"
    mgmt_mac = "52:54:00:38:a1:62"
    rootdisk = 107374182400
    datadisk-0 = 107374182400
    datadisk-1 = 1
    datadisk-2 = 1
  },
  {
    name = "A-1"
    running = "false"
    rootdisk = "1073741824"
    memory = "20480"
    vcpus = "4"
    mgmt_mac = "52:54:00:50:1a:a4"
    rootdisk = 107374182400
    datadisk-0 = 107374182400
    datadisk-1 = 1
    datadisk-2 = 1
  },
  {
    name = "A-2"
    running = "false"
    rootdisk = "1073741824"
    memory = "20480"
    vcpus = "4"
    mgmt_mac = "52:54:00:32:7a:2a"
    rootdisk = 107374182400
    datadisk-0 = 107374182400
    datadisk-1 = 1
    datadisk-2 = 1
  },
  {
    name = "C-0"
    running = "false"
    rootdisk = "1073741824"
    memory = "30720"
    vcpus = "6"
    mgmt_mac = "52:54:00:47:7e:5a"
    rootdisk = 107374182400
    datadisk-0 = 107374182400
    datadisk-1 = 107374182400
    datadisk-2 = 107374182400
  },
  {
    name = "C-1"
    running = "false"
    rootdisk = "1073741824"
    memory = "30720"
    vcpus = "6"
    mgmt_mac = "52:54:00:6e:01:05"
    rootdisk = 107374182400
    datadisk-0 = 107374182400
    datadisk-1 = 107374182400
    datadisk-2 = 107374182400
  },
  {
    name = "C-2"
    running = "false"
    rootdisk = "1073741824"
    memory = "30720"
    vcpus = "6"
    mgmt_mac = "52:54:00:29:96:c0"
    rootdisk = 107374182400
    datadisk-0 = 107374182400
    datadisk-1 = 107374182400
    datadisk-2 = 107374182400
  },
]



#### Without OS, 2 Networks (4-5) and 1 data disks
servers_type_3 = [
  {
    name = "D-0"
    running = "false"
    rootdisk = "1073741824"
    memory = "4096"
    vcpus = "1"
    mgmt_mac = "52:54:00:19:10:be"
    rootdisk = 107374182400
    datadisk-0 = 107374182400
  },
  {
    name = "D-1"
    running = "false"
    rootdisk = "1073741824"
    memory = "4096"
    vcpus = "1"
    mgmt_mac = "52:54:00:35:93:89"
    rootdisk = 107374182400
    datadisk-0 = 107374182400
  },
]
