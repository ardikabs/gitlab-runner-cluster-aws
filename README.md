# gitlab-runner-aws
Simple project for spin up [gitlab-runner](https://docs.gitlab.com/runner/) cluster on AWS with some advanced configuration such as:<br>
1. Build with customized AMI with the help of [packer](https://packer.io/)
1. Build with autoscaling setup, also added with autoscaling schedule with the help of [terraform](https://terraform.io)

# Preqrequisites
1. [Packer](https://packer.io) v1.5
1. [Terraform](https://terraform.io) v0.12.25

# How To
### Build AMI with Packer
```bash
git clone https://github.com/ardikabs/gitlab-runner-cluster-aws
cd gitlab-runner-cluster-aws
./setup.sh packer

Setting up gitlab-runner cluster on AWS
Type the Gitlab URL to be used for gitlab-runner:
gitlab.com

Type the Registration Token for Gitlab Runner to be used for gitlab-runner:
Fhurp9yJ3T46_vwZ7t92

Type VPC Id to be used for building the AMI:
vpc-0ba5b3023a58bab6c

Type Public subnet Id to be used for building the AMI:
subnet-0ed6a2cee8c75f594

Running packer to build AMI for gitlab-runner on AWS
amazon-ebs: output will be in this color
.
.
.

```
### Setup gitlab-runner cluster within autoscaling group on AWS with Terraform
```bash
cd gitlab-runner-cluster-aws
./setup.sh terraform
Setting up gitlab-runner cluster on AWS

Type the gitlab-runner AMI to be used for gitlab-runner cluster:
ami-0beaa8ab3a1274c50

Type the instance type to be used for gitlab-runner cluster (default c5.large):

Type the desired capacity for gitlab-runner instance should be run in gitlab-runner cluster (default 5):

Type the minimal gitlab-runner instance should be run in gitlab-runner cluster (default 3):

Type the maximal gitlab-runner instance should be run in gitlab-runner cluster (default 10):

Type VPC id to be used for running gitlab-runner cluster:
vpc-0ba5b3023a58bab6c

Type Network Tier to be used for running gitlab-runner cluster:
utility

Running Terraform to spin up for gitlab-runner cluster on AWS
Initializing the backend...
.
.
.
```
### Clean up
```bash
./setup.sh destroy
```
