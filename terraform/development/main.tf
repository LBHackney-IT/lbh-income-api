provider "aws" {
  region  = "eu-west-2"
  version = "~> 2.0"
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
locals {
    application_name = "lbh income api"
    parameter_store = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter"
}

terraform {
  backend "s3" {
    bucket  = "terraform-state-housing-development"
    encrypt = true
    region  = "eu-west-2"
    key     = "services/lbh-income-api/state"
  }
}

resource "aws_ecr_repository" "income-api" {
    name                 = "hackney/apps/income-api"
    image_tag_mutability = "MUTABLE"
}

resource "aws_ecr_repository_policy" "income-api-policy" {
    repository = aws_ecr_repository.income-api.name
    policy     = <<EOF
  {
    "Version": "2008-10-17",
    "Statement": [
      {
        "Sid": "adds full ecr access to the demo repository",
        "Effect": "Allow",
        "Principal": "*",
        "Action": [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:CompleteLayerUpload",
          "ecr:GetDownloadUrlForLayer",
          "ecr:GetLifecyclePolicy",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
      }
    ]
  }
  EOF
}

resource "aws_ecs_cluster" "income-api-ecs-cluster" {
    name = "ecs-cluster-for-income-api"
}

resource "aws_ecs_service" "income-api-ecs-service" {
    name            = "income-api-ecs-service"
    cluster         = aws_ecs_cluster.income-api-ecs-cluster.id
    task_definition = aws_ecs_task_definition.income-api-ecs-task-definition.arn
    launch_type     = "FARGATE"
    network_configuration {
        subnets          = ["subnet-0140d06fb84fdb547", "subnet-05ce390ba88c42bfd"]
        security_groups = ["sg-00d2e14f38245dd0b"]
        assign_public_ip = true
    }
    desired_count = 1
}

resource "aws_ecs_task_definition" "income-api-ecs-task-definition" {
    family                   = "ecs-task-definition-income-api"
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    memory                   = "1024"
    cpu                      = "512"
    execution_role_arn       = "arn:aws:iam::364864573329:role/ecsTaskExecutionRole"
    container_definitions    = <<EOF
[
  {
    "name": "income-api-container",
    "image": "364864573329.dkr.ecr.eu-west-2.amazonaws.com/hackney/apps/income-api:latest",
    "memory": 1024,
    "cpu": 512,
    "essential": true,
    "entryPoint": ["/"],
    "portMappings": [
      {
        "containerPort": 3000,
        "hostPort": 3000
      }
    ]
  }
]
EOF
}
