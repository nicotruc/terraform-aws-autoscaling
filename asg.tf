######################################################################
## Security groups
######################################################################

resource "aws_security_group" "api" {
  vpc_id      = "${module.discovery.vpc_id}"
  name        = "${var.app_name}"
  description = "${var.app_name} - Security group"
  tags        = "${merge(var.app_tags, map("Name", format("%s", var.app_name)))}"

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Configuration of the firewall - Instances <-> ALB
resource "aws_security_group_rule" "api_tcp_8080_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.alb.id}"
  security_group_id        = "${aws_security_group.api.id}"
}

resource "aws_security_group_rule" "api_tcp_19999_alb" {
  type                     = "ingress"
  from_port                = 19999
  to_port                  = 19999
  protocol                 = "tcp"
  source_security_group_id = "${aws_security_group.alb.id}"
  security_group_id        = "${aws_security_group.api.id}"
}

# Configuration of the firewall - Instances <-> MyIp (Debugging purposes)
resource "aws_security_group_rule" "api_tcp_8080_myip" {
  type              = "ingress"
  from_port         = 8080
  to_port           = 8080
  protocol          = "tcp"
  cidr_blocks       = ["${trimspace(data.http.whatismyip.body)}/32"]
  security_group_id = "${aws_security_group.api.id}"
}

resource "aws_security_group_rule" "api_tcp_19999_myip" {
  type              = "ingress"
  from_port         = 19999
  to_port           = 19999
  protocol          = "tcp"
  cidr_blocks       = ["${trimspace(data.http.whatismyip.body)}/32"]
  security_group_id = "${aws_security_group.api.id}"
}

######################################################################
## Launch instances
######################################################################

resource "aws_instance" "api" {
  count                  = "${var.app_count}"
  subnet_id              = "${element(local.app_subnets, count.index)}"
  ami                    = "${local.app_ami_id}"
  key_name               = "${var.app_key_name}"
  instance_type          = "${var.app_instance_type}"
  vpc_security_group_ids = ["${local.ops_sg}", "${aws_security_group.api.id}"]
  tags                   = "${merge(var.app_tags,
    map("Name", format("%s-%02d", var.app_name, count.index)))}"
}

resource aws_lb_target_group_attachment "api_http" {
  count            = "${var.app_count}"
  target_group_arn = "${aws_lb_target_group.alb_tg_http.arn}"
  target_id        = "${element(aws_instance.api.*.id, count.index)}"
  port             = 8080
}

resource aws_lb_target_group_attachment "api_netdata" {
  count            = "${var.app_count}"
  target_group_arn = "${aws_lb_target_group.alb_tg_netdata.arn}"
  target_id        = "${element(aws_instance.api.*.id, count.index)}"
  port             = 19999
}
