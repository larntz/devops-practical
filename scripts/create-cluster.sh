#!/bin/bash

## packer build if necessary
if [ -d $PWD/packer-builds ]; then 
  echo $'\n\nalready packed, proceeding to terraform\n'
  packer build packer/debian.json
else
  echo $'\n\npack it up, pack it in, let us begin'
fi

# create vms and ansible host inventory
terraform -chdir=./terraform/ init
terraform -chdir=./terraform/ apply -auto-approve

# run asible playbook to configure cluster lb and kubespray global vars
ansible-playbook -i cluster-hosts ansible-playbooks/configure-cluster.yaml

echo "finished."

if [ $? == 0 ]; then 
  echo "export KUBECONFIG=$PWD/artifacts/admin.conf to access cluster."
else 
  echo "something went wrong."
fi
