#!/bin/bash

# destroy vms
terraform -chdir=./terraform/ apply -auto-approve -destroy

# clean up files
rm -f cluster-hosts ansible-playbooks/kubespray-global-vars.yaml .known_hosts
sudo rm -rf ./ansible-playbooks/kubespray/kubeconfig
