## Infrastructure Practical

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

## solution requirements

need to have:
  - qemu/libvirt on localhost with correct permissions for user
  - python3 and python3-venv 
  - terraform 
  - packer 
  - mkisofs for cloudinit

### bootstrap environment

1. git clone https://github.com/kubernetes-sigs/kubespray.git
1. mkdir venv && python3 -m venv ./venv/ && source ./venv/bin/activate{.fish for me}
1. pip install -r kubespray/requirements.txt
1. pip install git+https://salsa.debian.org/apt-team/python-apt (running from debian 10)


## solution deploy

1. ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook ...




## references

- [packer flatcar example](https://github.com/flatcar-linux/flatcar-packer-qemu)
- [python install on flatcar example](https://github.com/vmware/ansible-coreos-bootstrap)
