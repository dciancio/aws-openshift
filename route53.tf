data "aws_route53_zone" "public" {
  name = var.domain
}

resource "aws_route53_record" "dns_master" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = local.public_api_hostname
  type    = "A"
  alias {
    name                   = aws_lb.master_lb.dns_name
    zone_id                = aws_lb.master_lb.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "dns_master_int" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = local.api_hostname
  type    = "A"
  alias {
    name                   = aws_lb.master_lb_int.dns_name
    zone_id                = aws_lb.master_lb_int.zone_id
    evaluate_target_health = true
  }
}

resource "aws_route53_record" "dns_subdomain" {
  zone_id = data.aws_route53_zone.public.zone_id
  name    = "*.${local.public_subdomain}"
  type    = "A"
  alias {
    name                   = aws_lb.infra_lb.dns_name
    zone_id                = aws_lb.infra_lb.zone_id
    evaluate_target_health = false
  }
}

