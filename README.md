# Rancher host cluster Terraform module

This is a terraform module to help with creating a rancher host cluster. It is intended for use in combination with [my Rancher server module](https://github.com/greensheep/terraform-aws-rancher-server).

### Features

- Flexible for use with different deployment scenarios.
- Automatically adds hosts launched by autoscaling to the Rancher server.
- Registers autoscaling lifecycle hook used to automatically remove instances from the Rancher server on scale down (see [my Rancher server module](https://github.com/greensheep/terraform-aws-rancher-server)).
- Designed for use in VPC private subnets so can be used for private, backend services or proxy traffic from an ELB for public services.
- Can be used unlimited times in a terraform config. Allows creation of separate clusters for dev, staging, production, etc.

### Requirements

Terraform 0.6.6 is required.

On it's own this doesn't do very much. It needs to be included in a Terraform config that creates the following resources:

- Security group
- Autoscaling launch configuration
- Autoscaling group

Because these resources may vary significantly for your deployment (eg, the type of app you're deploying, expected workload, etc), you need to create these yourself and pass in the necessary variables.

You'll also need to have your Rancher server setup & configured (did I mention [my Rancher server module](https://github.com/greensheep/terraform-aws-rancher-server)!). Don't be tempted to use this as part of some mega-config that also creates the server.. you need to specify an environment id and API access keys for it to work!

### Usage

Include the following in your existing terraform config:

    module "staging_cluster" {

        # Import the module from Github
        # It's probably better to fork or clone this repo if you intend to use in production
        # so any future changes dont mess up your existing infrastructure.
        source = "github.com/greensheep/terraform-aws-rancher-hosts"

        # Add Rancher server details
        server_security_group_id = "sg-XXXXXXXX"
        server_hostname          = "rancher-server.yourdomain.tld"

        # Rancher environment
        # In your Rancher server, create an environment and an API keypair. You can have
        # multiple host clusters per environment if necessary. Instances will be labelled
        # with the cluster name so you can differentiate between multiple clusters.
        environment_id         = "1a7"
        environment_access_key = "ACCESS-KEY"
        environment_secret_key = "SECRET-KET"

        # Name your cluster and provide the autoscaling group name and security group id.
        # See examples below.
        cluster_name                       = "${var.cluster_name}"
        cluster_autoscaling_group_name     = "${aws_autoscaling_group.cluster_autoscale_group.id}"
        cluster_instance_security_group_id = "${aws_security_group.rancher_host_sg.id}"

        # Lifecycle hooks queue ARN
        # This is specific to my Rancher server module which creates the SQS queue used to
        # received autoscaling lifecycle hooks. This module creates a lifecycle hook for the
        # provided autoscaling group so that instances can be removed from the Rancher
        # server before they are terminated.
        lifecycle_hooks_sqs_queue_arn = "${var.lifecycle_hooks_sqs_queue_arn}"

    }

### Examples of required resources

##### Security group

    # Cluster instance security group
    resource "aws_security_group" "cluster_instance_sg" {

        name = "Cluster-Instances"
        description = "Rules for connected Rancher host machines. These are the hosts that run containers placed on the cluster."
        vpc_id = "${TARGET-VPC-ID}"

        # NOTE: To allow ELB proxied traffic to private VPC
        #       hosts, open the necessary ports here..

        lifecycle {
            create_before_destroy = true
        }

    }


##### Autoscaling

    # Autoscaling launch configuration
    resource "aws_launch_configuration" "cluster_launch_conf" {

        name = "Launch-Config"

        # Amazon linux, eu-west-1
        image_id = "ami-69b9941e"

        # No public ip when instances are placed in private subnets. See notes
        # about creating an ELB to proxy public traffic into the cluster.
        associate_public_ip_address = false

        # Security groups
        security_groups = [
            "${aws_security_group.cluster_instance_sg.id}"
        ]

        # Key
        # NOTE: It's a good idea to use the same key as the Rancher server here.
        key_name = "${UPLOADED-KEY-NAME}"

        # Add rendered userdata template
        user_data = "${module.staging_cluster.host_user_data}"

        # Misc
        instance_type = "t2.micro"
        enable_monitoring = true

        lifecycle {
            create_before_destroy = true
        }

    }

    # Autoscaling group
    resource "aws_autoscaling_group" "cluster_autoscale_group" {

        name = "Cluster-ASG"
        launch_configuration = "${aws_launch_configuration.cluster_launch_conf.name}"
        min_size = "2"
        max_size = "2"
        desired_capacity = "2"
        health_check_grace_period = 180
        health_check_type = "EC2"
        force_delete = false
        termination_policies = ["OldestInstance"]

        # Add ELB's here if you're proxying public traffic into the cluster
        # load_balancers = ["${var.instance_cluster_load_balancers}"]

        # Target subnets
        vpc_zone_identifier = ["${LIST-OF-VPC-PRIVATE-SUBNET-IDS}"]

        tag {
            key = "Name"
            value = "Test-Cluster-Instance"
            propagate_at_launch = true
        }

        lifecycle {
            create_before_destroy = true
        }

    }
