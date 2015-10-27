# Attach IPSEC rules to host instance security group.
# Enables the rancher overlay network for connected hosts.
# Traffic only allowed from other machines with this security group.
resource "aws_security_group_rule" "ipsec_ingress_1" {

    security_group_id = "${var.cluster_instance_security_group_id}"
    type = "ingress"
    from_port = 4500
    to_port = 4500
    protocol = "udp"
    source_security_group_id = "${var.cluster_instance_security_group_id}"

    lifecycle {
        create_before_destroy = true
    }

}

resource "aws_security_group_rule" "ipsec_ingress_2" {

    security_group_id = "${var.cluster_instance_security_group_id}"
    type = "ingress"
    from_port = 500
    to_port = 500
    protocol = "udp"
    source_security_group_id = "${var.cluster_instance_security_group_id}"

    lifecycle {
        create_before_destroy = true
    }

}

# SSH ingress
# Required for the server to connect & configure the host.
resource "aws_security_group_rule" "ssh_ingress" {

    security_group_id = "${var.cluster_instance_security_group_id}"
    type = "ingress"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    source_security_group_id = "${var.server_security_group_id}"

    lifecycle {
        create_before_destroy = true
    }

}

# Outgoing HTTP
# Allows pulling of remote docker images, installing packages, etc.
resource "aws_security_group_rule" "http_egress" {

    security_group_id = "${var.cluster_instance_security_group_id}"
    type = "egress"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    lifecycle {
        create_before_destroy = true
    }

}

# Outgoing HTTPS
# Allows pulling of remote docker images, installing packages, etc.
resource "aws_security_group_rule" "https_egress" {

    security_group_id = "${var.cluster_instance_security_group_id}"
    type = "egress"
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

    lifecycle {
        create_before_destroy = true
    }

}
