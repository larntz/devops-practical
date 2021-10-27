#!/bin/bash
if [ -d $PWD/packer-builds ]; then 
  echo $'\n\nalready packed, proceeding to terraform\n'
  echo ""
else
  echo $'\n\npack it up, pack it in, let us begin'
  echo $'packing'
fi

# create vms and ansible host inventory
echo "terraform -chdir=./terraform/ apply -auto-approve"

# run asible playbook to configure cluster lb and kubespray global vars
echo "ansible-playbook -i cluster-hosts ansible-playbooks/configure-cluster.yaml"

echo "finished."
echo "export KUBECONFIG=$PWD/artifacts/admin.conf to access cluster"

