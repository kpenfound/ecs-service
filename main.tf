resource "aws_ecs_task_definition" "task" {
  family = "${var.name}"

  container_definitions = <<DEFINITION
[
  {
    "cpu": ${var.task_cpu},
    "environment": [],
    "essential": true,
    "image": "${var.docker_image}",
    "memory": ${var.task_memory},
    "memoryReservation": ${var.task_memory_reservation},
    "name": "${var.name}"
  }
]
DEFINITION
}

resource "aws_ecs_service" "service" {
  name            = "${var.name}"
  cluster         = "${var.cluster_id}"
  task_definition = "${aws_ecs_task_definition.task.arn}"
  desired_count   = 3
  iam_role        = "${aws_iam_role.service_role.arn}"
  depends_on      = ["aws_iam_role_policy.service_role_policy"]

  ordered_placement_strategy {
    type  = "binpack"
    field = "cpu"
  }

  load_balancer {
    target_group_arn = "${aws_lb_target_group.alb_target_group.arn}"
    container_name   = "${var.name}"
    container_port   = 80
  }
}

resource "aws_iam_role" "service_role" {
  name = "${var.name}-service-role"

  assume_role_policy = <<EOF
{
    "Version": "2008-10-17",
    "Statement": [
        {
            "Sid": "",
            "Effect": "Allow",
            "Principal": {
                "Service": "ec2.amazonaws.com"
        },
        "Action": [
            "sts:AssumeRole"
        ]
        }
    ]
}
EOF
}

resource "aws_iam_role_policy" "service_role_policy" {
  name   = "${var.name}-service-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ec2:AuthorizeSecurityGroupIngress",
                "ec2:Describe*",
                "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
                "elasticloadbalancing:DeregisterTargets",
                "elasticloadbalancing:Describe*",
                "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
                "elasticloadbalancing:RegisterTargets"
            ],
            "Resource": "*"
        }
    ]
}
EOF
}

resource "aws_lb_target_group" "alb_target_group" {
  name     = "${var.name}-alb-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = "${var.vpc_id}"
}

resource "aws_lb_listener" "alb_listener" {
  load_balancer_arn = "${aws_lb.alb.arn}"
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.alb_target_group.arn}"
  }
}

resource "aws_security_group" "alb_sg" {
  name   = "${var.name}-alb-sg"
  vpc_id = "${var.vpc_id}"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "alb" {
  name               = "${var.name}-alb"
  internal           = false
  load_balancer_type = "application"

  security_groups = ["${aws_security_group.alb_sg.id}"]
  subnets         = ["${var.subnet_ids}"]
}
