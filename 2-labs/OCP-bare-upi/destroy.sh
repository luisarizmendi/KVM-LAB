#!/bin/bash







echo "****  DESTROY THE LAB   ****"




echo "**** DESTROY INFRA  ****"


  cd 1-create_infra/
  ./run.sh --destroy
  if [ $? -ne 0 ];
  then
      FAILED=1
  fi
  cd ..
