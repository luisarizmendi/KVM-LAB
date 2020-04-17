 #/bin/bash

# Create htpasswd file with users
sudo yum install -y httpd-tools
htpasswd -c -B -b users.htpasswd clusteradmin redhat
htpasswd -b users.htpasswd devuser redhat
htpasswd -b users.htpasswd viewuser redhat


# Assign htpasswd file to auth provisioner and enable provisioner
/usr/local/bin/oc create secret generic htpass-secret --from-file=htpasswd=users.htpasswd -n openshift-config
/usr/local/bin/oc apply -f descriptors.yaml


# Create cluster admin
/usr/local/bin/oc adm policy add-cluster-role-to-user cluster-admin clusteradmin


# Create groups
/usr/local/bin/oc adm groups new developers devuser
/usr/local/bin/oc adm groups new reviewers viewuser


# Assign roles to groups
/usr/local/bin/oc adm policy add-cluster-role-to-group view reviewers
/usr/local/bin/oc adm policy add-role-to-group admin developers
