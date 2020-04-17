#!/bin/bash

IS_OC_USER=no
IS_OC_USER=$(oc auth can-i create pods)
if [ $IS_OC_USER = no ]; then echo ""; echo "YOU NEED TO LOG IN OPENSHIFT CLUSTER!"; echo ""; exit -1;fi;

IS_CLUSTER_ADMIN=no
IS_CLUSTER_ADMIN=$(oc auth can-i create pods --all-namespaces)
if [ $IS_CLUSTER_ADMIN = no ]
then
  echo "You are NOT running this command as clusteradmin"
  exit -1
else
  POD_LIST=$(oc get pods --all-namespaces)
fi




echo ""
echo "Pods not in Running or Complete state:"
echo "--------------------------------------"

echo "$POD_LIST" | grep -v Complete | grep -v Running


echo ""
echo "Pods with Restarts:"
echo "--------------------------------------"



  totallines=$(echo "$POD_LIST"| wc -l)
  linenum=2
  linestoshow=""
  while [ $linenum -le $totallines ]
  do

     value=$(echo "$POD_LIST" | awk "NR==$linenum" | awk '{print $5}')

     if [ $value != 0 ]
     then
          linestoshow="$linestoshow $linenum"
     fi

     linenum=$((linenum+1))
  done


echo "$(echo "$POD_LIST" | awk "NR==1" )"
for i in $linestoshow; do echo "$(echo "$POD_LIST" | awk "NR==$i" )";done





echo ""
echo "Pods with not all containers ready"
echo "--------------------------------------"

POD_LIST_NO_COMPLETE=$(echo "$POD_LIST" | grep -v Complete )

  totallines=$(echo "$POD_LIST_NO_COMPLETE"| wc -l)
  linenum=2
  linestoshow=""
  while [ $linenum -le $totallines ]
  do

     value=$(echo "$POD_LIST_NO_COMPLETE" | awk "NR==$linenum" | awk '{print $3}')

     if [ $(echo $value | awk -F / '{print $1}') != $(echo $value | awk -F / '{print $2}') ]
     then
          linestoshow="$linestoshow $linenum"
     fi

     linenum=$((linenum+1))
  done


echo "$(echo "$POD_LIST_NO_COMPLETE" | awk "NR==1" )"
for i in $linestoshow; do echo "$(echo "$POD_LIST_NO_COMPLETE" | awk "NR==$i" )";done
