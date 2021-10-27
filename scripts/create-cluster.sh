#!/bin/bash

## packer build if necessary
if [ -d $PWD/packer-builds ]; then 
  echo $'\n\nalready packed, proceeding to terraform\n'
else
  echo $'\n\npack it up, pack it in, let us begin'
  packer build packer/debian.json
fi

# create vms and ansible host inventory
terraform -chdir=./terraform/ init
terraform -chdir=./terraform/ apply -auto-approve

# run ansible playbook to configure cluster lb, set kubespray global vars, 
#   run kubespray cluster.yaml playbook, and do post kubespray cluster configuration.
ansible-playbook -i cluster-hosts ansible-playbooks/configure-cluster.yaml

echo "finished."

if [ $? == 0 ]; then 
  echo "export KUBECONFIG=$PWD/ansible-playbooks/kubespray/kubeconfig/admin.conf to access cluster."
else 
  echo "something went wrong."
fi
