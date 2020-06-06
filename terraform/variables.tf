variable "application_name" {
  type = string
  description = "Application name"
  default = "gitlab-runner"
}

variable "launch_config_ami_id" {
  type = string
  description = "Selected AMI Id to be used on launch configuration"
}

variable "launch_config_instance_type" {
  type = string
  description = "Selected instance type to be used on launch configuration"
  default = "t2.micro"
}

variable "desired_capacity" {
  type = number
  description = "Number of desired capacity of instances should be running in the group"
  default = 5
}

variable "min_instance_size" {
  type = number
  description = "Minimal size of instances should be running in the group"
  default = 3
}

variable "max_instance_size" {
  type = number
  description = "Maximal size of instances should be running in the group"
  default = 10
}

variable "vpc_id" {
  type = string
  description = "VPC id used for the instances"
}

variable "subnet_ids" {
  type = list(string)
  description = "VPC id used for the instances. Recommend used private subnet."
  default = []
}

variable "tier" {
  type = string
  description = "Tier used for the instances. Recommend used tier for utility or any tier that kind of private subnet"
}
