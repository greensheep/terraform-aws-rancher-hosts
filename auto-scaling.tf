# User-data template
# Registers the instance with the rancher server environment
resource "template_file" "user_data" {

    template = "${file("${path.module}/files/userdata.template")}"
    vars {
        cluster_name            = "${var.cluster_name}"
        cluster_instance_labels = "${var.cluster_instance_labels}"
        environment_id          = "${var.environment_id}"
        environment_access_key  = "${var.environment_access_key}"
        environment_secret_key  = "${var.environment_secret_key}"
        server_hostname         = "${var.server_hostname}"
    }

    lifecycle {
        create_before_destroy = true
    }

}

# Lifecycle hook
# Triggered when an instance should be removed from the autoscaling
# group. Publishes a message to the supplied SQS queue so that the host
# can be removed from the Rancher server before shutting down.
resource "aws_autoscaling_lifecycle_hook" "cluster_instance_terminating_hook" {

    name = "cluster_instance_terminating_hook"
    autoscaling_group_name = "${var.cluster_autoscaling_group_name}"
    lifecycle_transition = "autoscaling:EC2_INSTANCE_TERMINATING"
    default_result = "CONTINUE"

    # 10 mins for rancher server to remove instance
    heartbeat_timeout = 600

    # Notification SQS queue
    notification_target_arn = "${var.lifecycle_hooks_sqs_queue_arn}"

    role_arn = "${aws_iam_role.lifecycle_role.arn}"

    lifecycle {
        create_before_destroy = true
    }

}

output "host_user_data" {
    value = "${template_file.user_data.rendered}"
}
