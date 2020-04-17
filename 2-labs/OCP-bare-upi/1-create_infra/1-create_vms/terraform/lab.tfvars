
#########################################################################################
# GENERAL
#
kvm_uri = "qemu:///system"
kvm_pool-VMs = "vms"
kvm_pool-bases = "bases"


#########################################################################################
# Network
#
networks = [
     {
       name = "net_ext"
       cidr = "1.50.10.0/24"
       mode = "route"
       bridge = "virbr-net-ext"
       domain = "136.243.40.222.nip.io"
       dhcp = "true"
       dns = "true"
     },
     {
       name = "net_int"
       cidr = "1.50.20.0/24"
       mode = "route"
       bridge = "virbr-net-int"
       domain = "136.243.40.222.nip.io"
       dhcp = "false"
       dns = "false"
     },
     {
       name = "storage"
       cidr = "1.50.30.0/24"
       mode = "route"
       bridge = "virbr-net-sto"
       domain = "136.243.40.222.nip.io"
       dhcp = "false"
       dns = "false"
     },
     {
       name = "baremetal"
       cidr = "1.50.40.0/24"
       mode = "route"
       bridge = "virbr-net-bar"
       domain = "136.243.40.222.nip.io"
       dhcp = "false"
       dns = "false"
     },
]



#########################################################################################
# Servers
#

cloudinitname = "cloudinitrhel.iso"

#### With OS, 2 Networks (0 and 1) and 2 data disks
servers_R1 = [
  {
    name = "ocp-installer"
    running = "true"
    baseimage = "rhel-server-7.6-x86_64-kvm.qcow2"
    memory = "4096"
    vcpus = "2"
    mgmt_ip = "1.50.10.2"
    rootdisk = 10737418240
    datadisk-0 = 10737418240
  },
]



#### With OS, 1 Networks (1) and 2 data disks
servers_R2 = [
  {
    name = "ocp-helper"
    running = "true"
    baseimage = "rhel-server-7.6-x86_64-kvm.qcow2"
    memory = "4096"
    vcpus = "2"
    mgmt_ip = "1.50.20.3"
    rootdisk = 107374182400
    datadisk-0 = 10737418240
  },
]

servers_type_bareOCP = [
  {
    name = "ocp-bootstrap"
    running = "false"
    #baseimage = "rhcos.qcow2"
    memory = "4092"
    vcpus = "2"
    mgmt_mac = "52:54:60:60:72:67"
    rootdisk = 107374182400
    datadisk-0 = 1
    datadisk-1 = 1
    datadisk-2 = 1
  },
  {
    name = "ocp-master0"
    #baseimage = "rhcos.qcow2"
    running = "false"
    memory = "16384"
    vcpus = "4"
    mgmt_mac = "52:54:60:e7:9d:67"
    rootdisk = 107374182400
    datadisk-0 = 53687091200
    datadisk-1 = 1
    datadisk-2 = 1
  },
  {
    name = "ocp-master1"
    #baseimage = "rhcos.qcow2"
    running = "false"
    memory = "16384"
    vcpus = "4"
    mgmt_mac = "52:54:60:80:16:23"
    rootdisk = 107374182400
    datadisk-0 = 53687091200
    datadisk-1 = 1
    datadisk-2 = 1
  },
  {
    name = "ocp-master2"
    #baseimage = "rhcos.qcow2"
    running = "false"
    memory = "16384"
    vcpus = "4"
    mgmt_mac = "52:54:60:d5:1c:39"
    rootdisk = 107374182400
    datadisk-0 = 53687091200
    datadisk-1 = 1
    datadisk-2 = 1
  },
  {
    name = "ocp-worker0"
    #baseimage = "rhcos.qcow2"
    running = "false"
    memory = "30720"
    vcpus = "8"
    mgmt_mac = "52:54:60:f4:26:a1"
    rootdisk = 53687091200
    datadisk-0 = 53687091200
    datadisk-1 = 322122547200
    datadisk-2 = 1
  },
  {
    name = "ocp-worker1"
    #baseimage = "rhcos.qcow2"
    running = "false"
    memory = "30720"
    vcpus = "8"
    mgmt_mac = "52:54:60:82:90:00"
    rootdisk = 53687091200
    datadisk-0 = 53687091200
    datadisk-1 = 322122547200
    datadisk-2 = 1
  },
#  {
#    name = "ocp-worker2"
#    #baseimage = "rhcos.qcow2"
#    running = "false"
#    memory = "30720"
#    vcpus = "8"
#    mgmt_mac = "52:54:60:8e:10:34"
#    rootdisk = 53687091200
#    datadisk-0 = 53687091200
#    datadisk-1 = 322122547200
#    datadisk-2 = 1
#  },
#  {
#    name = "ocp-worker3"
#    #baseimage = "rhcos.qcow2"
#    running = "false"
#    memory = "30720"
#    vcpus = "8"
#    mgmt_mac = "52:54:60:11:11:11"
#    rootdisk = 53687091200
#    datadisk-0 = 53687091200
#    datadisk-1 = 322122547200
#    datadisk-2 = 1
#  },
]
