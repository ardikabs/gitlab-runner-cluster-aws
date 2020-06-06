#!/usr/bin/env bash

function _packer(){

    echo -e "Setting up gitlab-runner AMI on AWS"

    echo "Type the Gitlab URL to be used for gitlab-runner: "
    read gitlab_url
    export PKR_VAR_gitlab_url=${gitlab_url}

    echo "Type the Registration Token for Gitlab Runner to be used for gitlab-runner: "
    read gitlab_reg_token
    export PKR_VAR_gitlab_reg_token=${gitlab_reg_token}

    echo "Type VPC Id to be used for building the AMI: "
    read vpc_id
    export PKR_VAR_vpc_id=${vpc_id}

    echo "Type Public subnet Id to be used for building the AMI: "
    read subnet_id
    export PKR_VAR_subnet_id=${subnet_id}

    echo "Running packer to build AMI for gitlab-runner on AWS"
    packer build packer/
}

function _terraform(){
    echo -e "Setting up gitlab-runner cluster on AWS"

    echo "Type the gitlab-runner AMI to be used for gitlab-runner cluster: "
    read gitlab_runner_ami
    export TF_VAR_launch_config_ami_id=${gitlab_runner_ami}


    echo "Type the instance type to be used for gitlab-runner cluster (default c5.large): "
    read gitlab_runner_instance_type
    export TF_VAR_launch_config_instance_type=${gitlab_runner_instance_type:-c5.large}

    echo "Type the desired capacity for gitlab-runner instance should be run in gitlab-runner cluster (default 5): "
    read gitlab_runner_desired_capacity
    export TF_VAR_desired_capacity=${gitlab_runner_desired_capacity:-5}

    echo "Type the minimal gitlab-runner instance should be run in gitlab-runner cluster (default 3): "
    read gitlab_runner_min_instance_size
    export TF_VAR_min_instance_size=${gitlab_runner_min_instance_size:-3}

    echo "Type the maximal gitlab-runner instance should be run in gitlab-runner cluster (default 10): "
    read gitlab_runner_max_instance_size
    export TF_VAR_max_instance_size=${gitlab_runner_max_instance_size:-10}

    echo "Type VPC id to be used for running gitlab-runner cluster: "
    read vpc_id
    export TF_VAR_vpc_id=${vpc_id}

    echo "Type Network Tier to be used for running gitlab-runner cluster: "
    read network_tier
    export TF_VAR_tier=${network_tier}

    echo "Running Terraform to spin up for gitlab-runner cluster on AWS"
    bash -c "
        cd terraform/

        terraform init
        terraform validate
        terraform apply -auto-approve
    "
}

function _terraform_destroy(){
    bash -c "
        cd terraform/

        terraform destroy -auto-approve
    "
}

function main(){
    local CONTINUE
    CONTINUE=1

    CHOICE=${1:-''}

    if [[ "$CHOICE" == "packer" ]]; then
        _packer
    elif [[ "$CHOICE" == "terraform" ]]; then
        _terraform
    elif [[ "$CHOICE" == "destroy" ]]; then
        _terraform_destroy
    fi
}

main "$@"