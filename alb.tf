######################################################################
## Security groups
######################################################################

resource "aws_security_group" "alb" {
  vpc_id      = "${module.discovery.vpc_id}"
  name        = "${var.app_name}-alb"
  description = "${var.app_name} - ALB Security group"
  tags        = "${merge(var.app_tags, map("Name", format("%s-alb", var.app_name)))}"

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Configuration of the firewall - ALB <-> World
resource "aws_security_group_rule" "alb_tcp_80_world" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = "${aws_security_group.alb.id}"
}

# Configuration of the firewall - ALB <-> MyIp
resource "aws_security_group_rule" "alb_tcp_19999_myip" {
  type              = "ingress"
  from_port         = 19999
  to_port           = 19999
  protocol          = "tcp"
  cidr_blocks       = ["${trimspace(data.http.whatismyip.body)}/32"]
  security_group_id = "${aws_security_group.alb.id}"
}

######################################################################
## EC2 ALB
######################################################################

# Create an application load balancer
resource "aws_lb" "alb" {
  name            = "${var.app_name}-alb-public"
  security_groups = ["${aws_security_group.alb.id}"]
  subnets         = ["${values(module.discovery.public_subnets_json)}"]

  enable_deletion_protection = false

  tags = "${merge(var.app_tags,
    map("Name", format("%s", var.app_name)),
    map("Tier", "public"),
  )}"
}

# Create a target group for HTTP
resource "aws_lb_target_group" "alb_tg_http" {
  name     = "${var.app_name}-http"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = "${module.discovery.vpc_id}"

  health_check {
    path                = "/heartbeat"
    port                = "8080"       # Traefik dashboard port
    healthy_threshold   = 2
    unhealthy_threshold = 4
    interval            = 15
  }
}

# Create a target group for HTTP
resource "aws_lb_target_group" "alb_tg_netdata" {
  name     = "${var.app_name}-netdata"
  port     = 19999
  protocol = "HTTP"
  vpc_id   = "${module.discovery.vpc_id}"

  health_check {
    path                = "/heartbeat"
    port                = "8080"       # Traefik dashboard port
    healthy_threshold   = 2
    unhealthy_threshold = 4
    interval            = 15
  }
}

# Create an ALB listener for HTTP -> HTTP target group
resource "aws_lb_listener" "alb_listener_http" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.alb_tg_http.arn}"
    type             = "forward"
  }
}

# Create an ALB listener for Netdata
resource "aws_lb_listener" "alb_listener_netdata" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = "19999"
  protocol          = "HTTP"

  default_action {
    target_group_arn = "${aws_lb_target_group.alb_tg_netdata.arn}"
    type             = "forward"
  }
}
