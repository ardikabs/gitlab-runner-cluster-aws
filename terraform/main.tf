
data "aws_subnet_ids" "this" {
  count = length(var.subnet_ids) > 0 ? 0 : 1

  vpc_id = var.vpc_id == "" ? null : var.vpc_id

  filter {
    name = "tag:Tier"
    values = [
      var.tier
    ]
  }
}

resource "aws_launch_configuration" "this" {
  name_prefix = "${var.application_name}-launch-config"
  associate_public_ip_address = false

  image_id = var.launch_config_ami_id
  instance_type = var.launch_config_instance_type
}

resource "aws_autoscaling_group" "this" {

  name_prefix = "${var.application_name}-scaling-group"
  desired_capacity = var.desired_capacity

  min_size = var.min_instance_size
  max_size = var.max_instance_size

  vpc_zone_identifier = coalescelist(var.subnet_ids, length(data.aws_subnet_ids.this) > 0 ? data.aws_subnet_ids.this[0].ids[*] : [])
  launch_configuration = aws_launch_configuration.this.name

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_schedule" "startup" {
  autoscaling_group_name = aws_autoscaling_group.this.name
  scheduled_action_name = "${var.application_name}-cluster-startup"
  recurrence = "30 06 * * Mon-Fri"
  min_size = var.min_instance_size
  max_size = var.max_instance_size
  desired_capacity = var.desired_capacity
}

resource "aws_autoscaling_schedule" "shutdown" {
  autoscaling_group_name = aws_autoscaling_group.this.name
  scheduled_action_name = "${var.application_name}-cluster-shutdown"
  recurrence = "59 23 * * Mon-Fri"
  min_size = 1
  max_size = 2
  desired_capacity = 1
}
