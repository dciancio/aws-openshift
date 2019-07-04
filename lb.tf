resource "aws_lb" "master_lb" {
  name                             = "${var.clustername}-master-lb"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = aws_subnet.public.*.id
  idle_timeout                     = 350
  enable_cross_zone_load_balancing = false
  tags = {
    "Name"              = "${var.clustername}-master-lb"
    "${local.clustertagkey}" = "${local.clustertagvalue}"
  }
}

resource "aws_lb" "master_lb_int" {
  name                             = "${var.clustername}-master-lb-int"
  internal                         = true
  load_balancer_type               = "network"
  subnets                          = aws_subnet.private.*.id
  idle_timeout                     = 350
  enable_cross_zone_load_balancing = false
  tags = {
    "Name"              = "${var.clustername}-master-lb-int"
    "${local.clustertagkey}" = "${local.clustertagvalue}"
  }
}

resource "aws_lb" "infra_lb" {
  name                             = "${var.clustername}-infra-lb"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = aws_subnet.public.*.id
  idle_timeout                     = 350
  enable_cross_zone_load_balancing = false
  tags = {
    "Name"              = "${var.clustername}-infra-lb"
    "${local.clustertagkey}" = "${local.clustertagvalue}"
  }
}

resource "aws_lb_target_group" "master_lb_tg" {
  name     = "${var.clustername}-master-lb-tg"
  port     = "443"
  protocol = "TCP"
  vpc_id   = aws_vpc.default.id
  tags = {
    "Name"              = "${var.clustername}-master-lb-tg"
    "${local.clustertagkey}" = "${local.clustertagvalue}"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    port                = "443"
    protocol            = "HTTPS"
    path                = "/healthz"
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "master_lb_int_tg" {
  name        = "${var.clustername}-master-lb-int-tg"
  port        = "443"
  protocol    = "TCP"
  vpc_id      = aws_vpc.default.id
  target_type = "ip"
  tags = {
    "Name"              = "${var.clustername}-master-lb-int-tg"
    "${local.clustertagkey}" = "${local.clustertagvalue}"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3
    timeout             = 10
    interval            = 30
    port                = "443"
    protocol            = "HTTPS"
    path                = "/healthz"
    matcher             = "200-399"
  }
}

resource "aws_lb_target_group" "infra_lb_tg" {
  name     = "${var.clustername}-infra-lb-tg"
  port     = "80"
  protocol = "TCP"
  vpc_id   = aws_vpc.default.id
  tags = {
    "Name"              = "${var.clustername}-infra-lb-tg"
    "${local.clustertagkey}" = "${local.clustertagvalue}"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3

    #    timeout             = 10
    interval = 30
    port     = "80"
    protocol = "TCP"
  }
}

resource "aws_lb_target_group" "infra_lb_tg2" {
  name     = "${var.clustername}-infra-lb-tg2"
  port     = "443"
  protocol = "TCP"
  vpc_id   = aws_vpc.default.id
  tags = {
    "Name"              = "${var.clustername}-infra-lb-tg2"
    "${local.clustertagkey}" = "${local.clustertagvalue}"
  }

  health_check {
    healthy_threshold   = 3
    unhealthy_threshold = 3

    #    timeout             = 10
    interval = 30
    port     = "443"
    protocol = "TCP"
  }
}

resource "aws_lb_listener" "master_lb_listener" {
  load_balancer_arn = aws_lb.master_lb.arn
  port              = 443
  protocol          = "TCP"
  default_action {
    target_group_arn = aws_lb_target_group.master_lb_tg.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "master_lb_int_listener" {
  load_balancer_arn = aws_lb.master_lb_int.arn
  port              = 443
  protocol          = "TCP"
  default_action {
    target_group_arn = aws_lb_target_group.master_lb_int_tg.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "infra_lb_listener" {
  load_balancer_arn = aws_lb.infra_lb.arn
  port              = 80
  protocol          = "TCP"
  default_action {
    target_group_arn = aws_lb_target_group.infra_lb_tg.arn
    type             = "forward"
  }
}

resource "aws_lb_listener" "infra_lb_listener2" {
  load_balancer_arn = aws_lb.infra_lb.arn
  port              = 443
  protocol          = "TCP"
  default_action {
    target_group_arn = aws_lb_target_group.infra_lb_tg2.arn
    type             = "forward"
  }
}

resource "aws_lb_target_group_attachment" "master_lb_tg" {
  count            = var.master_count
  target_group_arn = aws_lb_target_group.master_lb_tg.arn
  target_id        = element(aws_instance.master.*.id, count.index)
  port             = 443
}

resource "aws_lb_target_group_attachment" "master_lb_int_tg" {
  count            = var.master_count
  target_group_arn = aws_lb_target_group.master_lb_int_tg.arn
  target_id        = element(aws_instance.master.*.private_ip, count.index)
  port             = 443
}

resource "aws_lb_target_group_attachment" "infra_lb_tg" {
  count            = var.infra_count
  target_group_arn = aws_lb_target_group.infra_lb_tg.arn
  target_id        = element(aws_instance.infra.*.id, count.index)
  port             = 80
}

resource "aws_lb_target_group_attachment" "infra_lb_tg2" {
  count            = var.infra_count
  target_group_arn = aws_lb_target_group.infra_lb_tg2.arn
  target_id        = element(aws_instance.infra.*.id, count.index)
  port             = 443
}

