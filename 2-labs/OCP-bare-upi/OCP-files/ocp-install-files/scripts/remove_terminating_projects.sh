#!/bin/bash

for ns in `kubectl get ns --field-selector status.phase=Terminating -o name | cut -d/ -f2`;  do   echo "apiservice under namespace $ns";   kubectl get apiservice -o json |jq --arg ns "$ns" '.items[] |select(.spec.service.namespace != null) | select(.spec.service.namespace == $ns) | .metadata.name ' --raw-output;   echo "api resources under namespace $ns";   for resource in `kubectl api-resources --verbs=list --namespaced -o name | xargs -n 1 kubectl get -o name -n $ns`;    do      echo $resource;   done; done > /tmp/tobedeleted



for i in $(cat /tmp/tobedeleted)
do
       oc delete $i --grace-period=0 --force > /dev/null 2>&1
       oc patch $i --type=merge -p '{"metadata": {"finalizers":null}}' > /dev/null 2>&1
done
