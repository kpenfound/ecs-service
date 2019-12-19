output "service_arn" {
    value = "${aws_ecs_service.service.arn}"
}

output "service_alb_arn" {
    value = "${aws_lb.alb.arn}"
}