#!/bin/bash

# create vms and ansible host inventory
terraform -chdir=./terraform/ apply -auto-approve


# run asible playbook to configure cluster lb and kubespray global vars
ansible-playbook -i cluster-hosts ansible-playbooks/configure-cluster.yaml

# run kubespray
ansible-playbook -i cluster-hosts -e @ansible-playbooks/kubespray-global-vars.yaml ansible-playbooks/kubespray/cluster.yml --become

echo "finished."
echo "export KUBEADMIN=$PWD/artifacts/admin.conf to access cluster"

