# Infrastructure Practical

  - Dockerize https://github.com/swimlane/devops-practical
  - MongoDB should also be deployed as a docker container
  - Create a Helm chart for the application and use Helm (v3) to deploy it to a Kubernetes cluster
  - You can use a hosted service like EKS/GKE/AKS or create your own cluster using Kubespray (https://github.com/kubernetes-sigs/kubespray ) or kURL ( https://kurl.sh/ )
  - Use terraform to create as much of the Kubernetes cluster and required infrastructure as possible

Eliminate as many single points of failure for your Kubernetes cluster deployment as possible

Bonus points for the following:
  - Security
  - Scalability
  - Using Ansible to ensure NTP is installed and running on the worker nodes
     - As well any dependencies needed for Kubernetes if not using EKS/GKE/AKS prebuilt images
  - Using Packer to create the worker node images and applying the Ansible playbook

Access the app running in Kubernetes, register for an account, and add a record.

To deliver your work, create a public Github repository with the following (at a minimum):
  - Readme with the commands used to deploy the Helm chart and Terraform
  - Helm chart
  - Terraform files
  - Dockerfiles
  - Screenshot of the running application with a new record added

If you don't make it through everything here we'd still like to see the progress you made and your thought process on the remaining work.

--- 

# Solution

## overview

This solution will build an HA k8s cluster on libvirt/qemu using the following tools:

  - packer
  - terraform
  - ansible

We will build an haproxy loadbalancer, three contorl plane nodes, and between 2-7 worker nodes. 

### prebuild steps

__NOTE:__ This was developed and tested on Debian 10. Other distros may have different requirements. 

1. Install debian packages on host system. The build-essentials package is arequired to build python-apt which is used by ansible. 
    ```
    apt install -y python3 python3-venv build-essentials 
    ```
1. Clone this code repository.
    ```
    git clone https://github.com/larntz/devops-practical.git devops-practical
    ```

__NOTE:__ _the remaining commands in this README should be exected from the repo's top level directory.

1. Clone the kubespray repository into the `ansible-playbooks` directory.
    ```
    git clone https://github.com/kubernetes-sigs/kubespray.git devops-practical/ansible-playbooks/kubespray
    ```
1. Move into the `devops-practical` directory.
    ```
    cd devops-practical
    ```
1. Create a python3 venv and activate it. 
    ```
    python3 -m venv ./venv
    source ./venv/bin/activate` __NOTE:__ you may need to source a different `activate` file if your shell isn't bash.
    ```
1. Install required python packages with pip.
    ```
    pip install -r ansible-playbooks/requirements/requirements.txt -r ansible-playbooks/kubespray/requirements.txt
    ```
1. Install required ansible-galaxy collections.
    ```
    ansible-galaxy install -r ansible-playbooks/requirements/requirements.yaml
    ```
    
### build steps

__NOTE:__ All commands should be run from the repo top level directory.

1. create the vm image with packer.
  - `packer build packer/debian.json`
1. deploy vm infrastructure using terraform
  - `terraform -chdir=terraform/ apply -auto-approve`
1. use ansible to configure loadblancer, kubespray vars, and install cert-manager, ingress-nginx, mongodb, and our devops-practical swimapp. 
  - `ansible-playbook -i cluster-hosts ansible-playbooks/configure-cluster.yaml`


## solution host system requirements

need to have:
  - qemu/libvirt on localhost with correct permissions for user
  - apt install -y python3 python3-venv build-essentials #build-essentials requried for building python-apt
  - terraform 
  - packer 
  - helm (helm diff plugin optional)
  - kubectl 
  - mkisofs for create cloudinit iso (terraform)

### bootstrap environment

1. git clone https://github.com/larntz/devops-practical.git && cd devops-practical
1. git clone https://github.com/kubernetes-sigs/kubespray.git ./ansible-playbooks/kubespray
1. mkdir venv && python3 -m venv ./venv/ && source ./venv/bin/activate{.fish for me}
1. pip install -r kubespray/requirements.txt
1. pip install git+https://salsa.debian.org/apt-team/python-apt (running required for running ansible apt module)
1. pip install openshift (for interation with kubernetes)

## solution deployment

### vm image creation

#### packer build

Packer will build a debian 11 images and save it to `../packer-builds/packer-debian-11.1-amd64-qemu/debian-11.1-amd64`. This images will be used by terraform in the next step. 

Packer also runs an ansible-playbook against the host to ensure all packages are updated to the latest version, and that the ntp service is enabled and started. 

From the packer/ directory run: 

```
packer build debian.json
```

### cluster deployment steps

#### terraform apply

terraform will build VMs running on libvirt.

The variables.tf file declares 2 variables:
 - `libvirt_url` specifies which libvirt host to use. Defaults to `qemu:///system`.
 - `worker_nodes` specifies how many worker nodes to deploy. Defaults to 2.

terraform will deploy one additional vm, lb-00.  This vm will run haproxy to loadbalancer the k8s apiserver. 

At the end of the run terraform will output an ansible inventory file named `cluster-hosts`. This file will be in the top level repo directory, and will be used by ansible and kubespray to configure the cluster.

cd into the terraform directory and run: 

```
terraform apply -auto-approve
```

#### ansible vm configuration

Before running the kubespray playbook, we will run the `configure-cluster.yaml` playbook in the `ansible-playbooks` directory. This playbook will set the system host name, install, enable, and configure haproxy on the lb-00 vm. It also generates the kubespray global variable file.

This command can be run from the repo's directory.

```
ansible-playbook -i cluster-hosts ansible-playbooks/configure-cluster.yaml
```

#### ansible kubespray run

kubespray's configuration file was crated in the prevous step. This config file contains lb-00's ip address, the metallb_ip_range and enables the local path provisioner (used by mongodb) and tells kubespray to save a copy of the cluster's kubeconfig locally.

This command be run from the repo's directory.

```
ansible-playbook -i cluster-hosts -e @ansible-playbooks/kubespray-global-vars.yaml ansible-playbooks/kubespray/cluster.yml --become
```

#### script to run each step of the cluster build

There is a simple script in the `scripts` directory that will run each step above sequentially. It's very crude at the moment and does not do any error handling.

Before running this script you must build the vm image running the packer command listed above. The vm image must bit in the follow location `./packer-builds/packer-debian-11.1-amd64-qemu/debian-11.1-amd64`.

```
./scripts/create-cluster.sh
```

script contents:

```
#!/bin/bash

# create vms and ansible host inventory
terraform -chdir=./terraform/ apply -auto-approve

# run asible playbook to configure cluster lb and kubespray global vars
ansible-playbook -i cluster-hosts ansible-playbooks/configure-cluster.yaml

# run kubespray
ansible-playbook -i cluster-hosts -e @ansible-playbooks/kubespray-global-vars.yaml ansible-playbooks/kubespray/cluster.yml --become

echo "finished..."
echo "export KUBECONFIG=$PWD/artifacts/admin.conf to access cluster"
```

### ingress-nginx and cert-manager deployment with helm

#### install ingress-nginx and cert-manager helm repos

```
helm repo add jetstack https://charts.jetstack.io
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
```

#### ingress-nginx

ingress-nginx can be installed with the default values. 

```
helm install ingress-nginx ingress-nginx/ingress-nginx -n ingress-nginx --create-namespace
```

#### cert-manager

cert-manager needs installed with `--set installCRDs=true` to install necessary CRDs with helm.

```
helm install cert-manager jetstack/cert-manager -n cert-manager --create-namespace --version v1.5.4 --set installCRDs=true
```

cert-manger also needs configured with a cluster-issuer. For this use case I create a self-signed issuer. 

```
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: selfsigned-cluster-issuer
spec:
  selfSigned: {}
```

### application deployment

There are two helm charts in this repo. One is `./helm-charts/mongo-chart.tgz` and the other is `./helm-charts/swim-chart.tgz`. 

The mongo-community-operator doesn't have a supported helm chart so I created one using the resources required. 

#### dockerization

The swimapp Dockerfile is located at `./docker/Dockerfile.swimapp`.


```
docker build -t larntz/swim:2021102401 -f Dockerfile.swimapp .
```


#### mongodb deployment

The mongo-chart will deploy the mongodb-community-operator and a 3 member cluster by default.

The values file options for this chart are:

```
mongodb:
  members: 3 # initial number of cluster members to deploy. Can be updated with `helm upgrade` to scale the cluster. 
  username:  # user to create
  password:  # new user's password
  database:  # the user will only be granted access to this database.
```

Edit the `mongo-values.yaml` file and then install the chart with this command from within the helm-charts directory:

```
helm install mongodb ./mongo-chart.tgz --namespace mongodb -f mongo-values.yaml
```

#### swim app deployment

The swim-chart will install the devops-practical application. 

The default values:

```
app:
  replicas: 3
  name: swim-app
  label: swim-app
  image:
    repository: larntz/swim
    tag: "2021102401"
  resources:
    limits:
      cpu: 1
      memory: 512Mi
    requests:
      cpu: 500m
      memory: 256Mi
  mongodb:
    # information required to construct the MONGODB_URL
    # these values should match the values used in the mongo-chart deployment.
    database:     # database name 
    username:     # username used to connect to the database 
    password:     # password used to connect ot the database
    svcName:      # this is required for constructing the MONGODB_URL
    namespace:    # this is required for constructing the MONGODB_URL
```

Helm chart install command (run from within the helm-charts directory): 


```
helm install swimapp ./swim-chart.tgz -n swimapp -f swim-values.yaml --create-namespace
```
