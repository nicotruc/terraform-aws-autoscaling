output "alb_endpoint" {
  value = "${aws_lb.alb.dns_name}"
}

