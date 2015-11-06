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

# Attach policy document for access to the sqs queue
resource "aws_iam_role_policy" "lifecycle_role_policy" {
    name = "${var.cluster_name}-lifecycle-hooks-policy"
    role = "${aws_iam_role.lifecycle_role.id}"
    policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Resource": "${var.lifecycle_hooks_sqs_queue_arn}",
    "Action": [
      "sqs:SendMessage",
      "sqs:GetQueueUrl",
      "sns:Publish"
    ]
  }]
}
EOF

    lifecycle {
        create_before_destroy = true
    }
    
}
