 #/bin/bash

/usr/local/bin/oc create -f descriptors.yaml

/usr/local/bin/oc adm policy add-scc-to-user hostmount-anyuid -n nfs-autoprovisioner -z nfs-client-provisioner

/usr/local/bin/oc create -f descriptors-2.yaml
