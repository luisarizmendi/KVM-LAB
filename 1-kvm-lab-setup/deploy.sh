#!/bin/bash

sudo yum install -y tmux ansible git

ansible-playbook ansible/setup.yaml  --extra-vars "int_external=eno1"
