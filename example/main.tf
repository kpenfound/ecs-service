provider "aws" {
  version = "~> 2.0"
  region  = "${var.region}"
}

resource "aws_default_vpc" "default" {
  tags = {
    Name = "Default VPC"
  }
}

data "aws_subnet_ids" "default" {
  vpc_id = "${aws_default_vpc.default.id}"
}

resource "aws_key_pair" "cluster_key" {
  key_name   = "ecs-cluster"
  public_key = "${file(var.public_key_file)}"
}

module "ecs_cluster" {
  source = "github.com/kpenfound/ecs-cluster?ref=1.0.1"

  region           = "${var.region}"
  ecs_ami          = "${var.ecs_ami}"
  ecs_instance_key = "${aws_key_pair.cluster_key.key_name}"
  cluster_name     = "${var.cluster_name}"
  vpc_id           = "${aws_default_vpc.default.id}"
  subnets          = "${data.aws_subnet_ids.default.ids}"
}

module "ecs_service" {
  source = "github.com/kpenfound/ecs-service?ref=0.0.1"

  cluster_id = "${var.cluster_name}"
  name = "test-service"
  docker_image = "nginx:latest"
  vpc_id = "${aws_default_vpc.default.id}"
  subnet_ids = "${data.aws_subnet_ids.default.ids}"
}
