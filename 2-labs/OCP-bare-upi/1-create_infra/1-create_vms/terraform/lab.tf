provider "libvirt" {
  uri = "${var.kvm_uri}"
}


#########################################################################################
# VARIABLES
#

variable "kvm_uri" {
  type = "string"
  default = "qemu:///system"
}


variable "kvm_pool-VMs" {
  type = "string"
  default = "vms"
}

variable "cloudinitname" {
  type = "string"
  default = "cloudinit.iso"
}

variable "kvm_pool-bases" {
  type = "string"
  default = "bases"
}


variable "networks" {
  type        = "list"
  description = "Lists the subnets to be created"
}



variable "servers_R1" {
  type        = "list"
  description = "Servers to create"
}


variable "servers_R2" {
  type        = "list"
  description = "Servers to create"
}


variable "servers_type_bareOCP" {
  type        = "list"
  description = "Servers to create"
}


#########################################################################################
# Network
#

# Create a network for our VMs
resource "libvirt_network" "networks" {
   count = "${length(var.networks)}"
   name = "${lookup(var.networks[count.index], "name")}"
   mode = "${lookup(var.networks[count.index], "mode")}"
   addresses = ["${lookup(var.networks[count.index], "cidr")}"]
   domain = "${lookup(var.networks[count.index], "domain")}"
   bridge = "${lookup(var.networks[count.index], "bridge")}"
   autostart = "true"
   dhcp {
    enabled = "${lookup(var.networks[count.index], "dhcp")}"
   }
   dns {
     enabled = "${lookup(var.networks[count.index], "dns")}"
   }
}




#########################################################################################
# Servers
#


data "template_file" "user_data" {
template = "${file("./cloud_init.cfg")}"
#  vars = {
#    var_to_inject = "${variable_name}"
#  }
}

#data "template_file" "network_config" {
#template = "${file("${path.module}/network_config.cfg")}"
#}


# Use CloudInit to add our ssh-key to the instance
resource "libvirt_cloudinit_disk" "cloudinit" {
  name = "${var.cloudinitname}"
  pool = "${var.kvm_pool-VMs}"
  user_data = "${data.template_file.user_data.rendered}"
#  network_config = "${data.template_file.network_config.rendered}"
}



#### With OS, 2 Networks (0 and 1) and 2 data disks ####################################



resource "libvirt_volume" "servers_R1-rootstorage" {
  count = "${length(var.servers_R1)}"
  name = "server_R1-${count.index}-root"
  pool = "${var.kvm_pool-VMs}"
  base_volume_name = "${lookup(var.servers_R1[count.index], "baseimage")}"
  base_volume_pool = "${var.kvm_pool-bases}"
  size =  "${lookup(var.servers_R1[count.index], "rootdisk")}"
}


resource "libvirt_volume" "servers_R1-datadisk-0" {
  count = "${length(var.servers_R1)}"
  name = "server_R1-${count.index}-datadisk-0"
  pool = "${var.kvm_pool-VMs}"
  size =  "${lookup(var.servers_R1[count.index], "datadisk-0")}"
}


resource "libvirt_domain" "servers_R1" {
  count = "${length(var.servers_R1)}"
  name = "${lookup(var.servers_R1[count.index], "name")}"
  running = "${lookup(var.servers_R1[count.index], "running") == "true" ? true : false}"
  memory = "${lookup(var.servers_R1[count.index], "memory")}"
  vcpu = "${lookup(var.servers_R1[count.index], "vcpus")}"

  cloudinit = "${libvirt_cloudinit_disk.cloudinit.id}"


  network_interface = [
    {
      network_id = "${libvirt_network.networks.0.id}"
      hostname =  "${lookup(var.servers_R1[count.index], "name")}"
      addresses = ["${lookup(var.servers_R1[count.index], "mgmt_ip")}"]
      wait_for_lease = true
    },
    {
      network_id = "${libvirt_network.networks.1.id}"
      addresses = ["0.1.${count.index}.0"]
    }
  ]

  cpu {
    mode = "host-passthrough"
  }

  disk = [
    {
      volume_id = "${element(libvirt_volume.servers_R1-rootstorage.*.id, count.index)}"
    },
    {
      volume_id = "${element(libvirt_volume.servers_R1-datadisk-0.*.id, count.index)}"
    }
  ]


  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
      type        = "pty"
      target_type = "virtio"
      target_port = "1"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }

}



#### With OS, 3 Networks (1) and 2 data disks ####################################



resource "libvirt_volume" "servers_R2-rootstorage" {
  count = "${length(var.servers_R2)}"
  name = "server_R2-${count.index}-root"
  pool = "${var.kvm_pool-VMs}"
  base_volume_name = "${lookup(var.servers_R2[count.index], "baseimage")}"
  base_volume_pool = "${var.kvm_pool-bases}"
  size =  "${lookup(var.servers_R2[count.index], "rootdisk")}"
}


resource "libvirt_volume" "servers_R2-datadisk-0" {
  count = "${length(var.servers_R2)}"
  name = "server_R2-${count.index}-datadisk-0"
  pool = "${var.kvm_pool-VMs}"
  size =  "${lookup(var.servers_R2[count.index], "datadisk-0")}"
}


resource "libvirt_domain" "servers_R2" {
  count = "${length(var.servers_R2)}"
  name = "${lookup(var.servers_R2[count.index], "name")}"
  running = "${lookup(var.servers_R2[count.index], "running") == "true" ? true : false}"
  memory = "${lookup(var.servers_R2[count.index], "memory")}"
  vcpu = "${lookup(var.servers_R2[count.index], "vcpus")}"

  cloudinit = "${libvirt_cloudinit_disk.cloudinit.id}"


  network_interface = [
    {
      network_id = "${libvirt_network.networks.1.id}"
      hostname =  "${lookup(var.servers_R2[count.index], "name")}"
      addresses = ["${lookup(var.servers_R2[count.index], "mgmt_ip")}"]
      wait_for_lease = true
    }
  ]

  cpu {
    mode = "host-passthrough"
  }

  disk = [
    {
      volume_id = "${element(libvirt_volume.servers_R2-rootstorage.*.id, count.index)}"
    },
    {
      volume_id = "${element(libvirt_volume.servers_R2-datadisk-0.*.id, count.index)}"
    }
  ]


  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
      type        = "pty"
      target_type = "virtio"
      target_port = "1"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }

}




#### Type OCP  ####################################



resource "libvirt_volume" "servers_type_bareOCP-rootstorage" {
  count = "${length(var.servers_type_bareOCP)}"
  name = "server_type_bareOCP-${count.index}-root"
  pool = "${var.kvm_pool-VMs}"
  #base_volume_name = "${lookup(var.servers_type_bareOCP[count.index], "baseimage")}"
  #base_volume_pool = "${var.kvm_pool-bases}"
  size =  "${lookup(var.servers_type_bareOCP[count.index], "rootdisk")}"
}

resource "libvirt_volume" "servers_type_bareOCP-datadisk-0" {
  count = "${length(var.servers_type_bareOCP)}"
  name = "server_type_bareOCP-${count.index}-datadisk-0"
  pool = "${var.kvm_pool-VMs}"
  size =  "${lookup(var.servers_type_bareOCP[count.index], "datadisk-0")}"
}

resource "libvirt_volume" "servers_type_bareOCP-datadisk-1" {
  count = "${length(var.servers_type_bareOCP)}"
  name = "server_type_bareOCP-${count.index}-datadisk-1"
  pool = "${var.kvm_pool-VMs}"
  size =  "${lookup(var.servers_type_bareOCP[count.index], "datadisk-1")}"
}

resource "libvirt_volume" "servers_type_bareOCP-datadisk-2" {
  count = "${length(var.servers_type_bareOCP)}"
  name = "server_type_bareOCP-${count.index}-datadisk-2"
  pool = "${var.kvm_pool-VMs}"
  size =  "${lookup(var.servers_type_bareOCP[count.index], "datadisk-2")}"
}


resource "libvirt_domain" "servers_type_bareOCP" {
  count = "${length(var.servers_type_bareOCP)}"
  running = "${lookup(var.servers_type_bareOCP[count.index], "running") == "true" ? true : false}"
  name = "${lookup(var.servers_type_bareOCP[count.index], "name")}"
  memory = "${lookup(var.servers_type_bareOCP[count.index], "memory")}"
  vcpu = "${lookup(var.servers_type_bareOCP[count.index], "vcpus")}"



  network_interface = [
    {
      network_id = "${libvirt_network.networks.1.id}"
      addresses = ["0.2.${count.index}.0"]
      mac = "${lookup(var.servers_type_bareOCP[count.index], "mgmt_mac")}"
    },
    {
      network_id = "${libvirt_network.networks.2.id}"
      addresses = ["0.5.${count.index}.0"]
    },
    {
      network_id = "${libvirt_network.networks.3.id}"
      addresses = ["0.5.${count.index}.0"]
    }
  ]


  disk = [
    {
      volume_id = "${element(libvirt_volume.servers_type_bareOCP-rootstorage.*.id, count.index)}"
    },
    {
      volume_id = "${element(libvirt_volume.servers_type_bareOCP-datadisk-0.*.id, count.index)}"
    },
    {
      volume_id = "${element(libvirt_volume.servers_type_bareOCP-datadisk-1.*.id, count.index)}"
    },
    {
      volume_id = "${element(libvirt_volume.servers_type_bareOCP-datadisk-2.*.id, count.index)}"
    }
  ]

  cpu {
    mode = "host-passthrough"
  }

  console {
    type        = "pty"
    target_port = "0"
    target_type = "serial"
  }

  console {
      type        = "pty"
      target_type = "virtio"
      target_port = "1"
  }

  graphics {
    type = "spice"
    listen_type = "address"
    autoport = "true"
  }

}



#########################################################################################
# OUTPUTS
#

output "servers_R1" {
  value = "${var.servers_R1}"
}
