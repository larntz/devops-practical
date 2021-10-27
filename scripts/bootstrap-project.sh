#!/bin/bash

# apt install stuff
#

# add hashicorp repositories
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
 
# add helm repositories
curl https://baltocdn.com/helm/signing.asc | sudo apt-key add -
echo "deb https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list

# add kubernetes repo
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

sudo apt update && sudo apt -y install packer terraform helm kubectl

# git clone kubespray
git clone https://github.com/kubernetes-sigs/kubespray.git ansible-playbooks/kubespray

# create python venv
python3 -m venv ./venv
# NOTE: you may need to source a different `activate` file if your shell isn't bash.
source ./venv/bin/activate 

# install python packages and ansible collections
pip install -r ansible-playbooks/requirements/requirements.txt -r ansible-playbooks/kubespray/requirements.txt
ansible-galaxy install -r ansible-playbooks/requirements/collections.yaml


