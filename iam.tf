# Autoscaling lifecycle hook role
# Allows lifecycle hooks to add messages to the SQS queue
resource "aws_iam_role" "lifecycle_role" {

    name = "${var.cluster_name}-lifecycle-hooks"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "autoscaling.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    lifecycle {
        create_before_destroy = true
    }

}

# AWS managed lifecycle hook policy
resource "aws_iam_policy_attachment" "lifecycle_role_policy" {

    name = "AutoScalingNotificationAccessRole"
    policy_arn = "arn:aws:iam::aws:policy/service-role/AutoScalingNotificationAccessRole"
    roles = [
        "${aws_iam_role.lifecycle_role.name}"
    ]

    lifecycle {
        create_before_destroy = true
    }

}
