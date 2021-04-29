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

data "aws_ssm_parameter" "housing_finance_db_host" {
  name = "/housing-finance/development/mysql-host"
}

data "aws_ssm_parameter" "housing_finance_db_database" {
  name = "/housing-finance/development/mysql-database"
}

data "aws_ssm_parameter" "housing_finance_db_username" {
  name = "/housing-finance/development/mysql-username"
}

data "aws_ssm_parameter" "housing_finance_db_password" {
  name = "/housing-finance/development/mysql-password"
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

#Elastic Container Registry (ECR) setup
resource "aws_ecr_repository_policy" "income-api-policy" {
    repository = aws_ecr_repository.income-api.name
    policy     = <<EOF
  {
    "Version": "2008-10-17",
    "Statement": [
      {
        "Sid": "adds full ecr access to the repository",
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
          "ecr:UploadLayerPart",
          "logs:CreateLogGroup"
        ]
      }
    ]
  }
  EOF
}

# Elastic Container Service (ECS) setup
resource "aws_ecs_cluster" "manage-arrears-ecs-cluster" {
  name = "ecs-cluster-for-manage-arrears"
}

resource "aws_ecs_service" "income-api-ecs-service" {
    name            = "income-api-ecs-service"
    cluster         = aws_ecs_cluster.manage-arrears-ecs-cluster.id
    task_definition = aws_ecs_task_definition.income-api-ecs-task-definition.arn
    launch_type     = "FARGATE"
    network_configuration {
        subnets          = ["subnet-0140d06fb84fdb547", "subnet-05ce390ba88c42bfd"]
        security_groups = ["sg-00d2e14f38245dd0b"]
        assign_public_ip = false
    }
    desired_count = 1
    load_balancer {
      target_group_arn = aws_lb_target_group.lb_tg.arn
      container_name   = "${var.app_name}-container"
      container_port   = var.app_port
  }
}

resource "aws_ecs_task_definition" "income-api-ecs-task-definition" {
    family                   = "ecs-task-definition-income-api"
    network_mode             = "awsvpc"
    requires_compatibilities = ["FARGATE"]
    memory                   = "4096"
    cpu                      = "512"
    execution_role_arn       = "arn:aws:iam::364864573329:role/ecsTaskExecutionRole"
    container_definitions    = <<DEFINITION
[
  {
    "name": "${var.app_name}-container",
    "image": "364864573329.dkr.ecr.eu-west-2.amazonaws.com/hackney/apps/income-api:latest",
    "memory": 4096,
    "cpu": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": ${var.app_port}
      }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "ecs-task-definition-${var.app_name}",
            "awslogs-region": "eu-west-2",
            "awslogs-stream-prefix": "${var.app_name}-logs"
        }
    },
    "environment": [
      {
        "name": "CUSTOMER_MANAGED_KEY",
        "value": "customer_key1"
      },
      {
        "name": "AWS_ACCESS_KEY_ID",
        "value": "access_key"
      },
      {
        "name": "AWS_SECRET_ACCESS_KEY",
        "value": "secret_key"
      },
      {
        "name": "AUTOMATE_INCOME_COLLECTION_LETTER_ONE",
        "value": "false"
      },
      {
        "name": "AUTOMATE_INCOME_COLLECTION_LETTER_TWO",
        "value": "false"
      },
      {
        "name": "AWS_REGION",
        "value": "eu-west-2"
      },
      {
        "name": "CAN_AUTOMATE_LETTERS",
        "value": "false"
      },
      {
        "name": "ENABLE_TENANCY_SYNC",
        "value": "false"
      },
      {
        "name": "GOV_NOTIFY_API_KEY",
        "value": "notify-key2"
      },
      {
        "name": "GOV_NOTIFY_SENDER_ID",
        "value": "sender-id"
      },
      {
        "name": "HARDCODED_TENANCIES",
        "value": "0114084/01,029533/01,0115514/01,030793/01,064966/01,007472/01,030793/01,0102966/02,046085/01,050678/01,0100984/01,065919/01,0900845/01,091549/01,022893/01,0106280/01,0100518/02,0906592/01,032494/01,036679/01,017526/01,0113066/01,016467/01,040939/01,066228/01,0111614/01,032494/01,033405/01,024667/01,0900226/01"
      },
      {
        "name": "INCOME_COLLECTION_API_HOST",
        "value": "https://g6bw0g0ojk.execute-api.eu-west-2.amazonaws.com/staging/tenancy/api/v1"
      },
      {
        "name": "INCOME_COLLECTION_API_KEY",
        "value": "ic_key"
      },
      {
        "name": "PATCH_CODES_FOR_LETTER_AUTOMATION",
        "value": "W02, W03"
      },
      {
        "name": "RACK_ENV",
        "value": "development"
      },
      {
        "name": "RAILS_ENV",
        "value": "development"
      },
      {
        "name": "RAILS_LOG_TO_STDOUT",
        "value": "true"
      },
      {
        "name": "REDIS_URL",
        "value": "redis://redis-staging.mfk1c9.ng.0001.euw2.cache.amazonaws.com:6379"
      },
      {
        "name": "SECRET_KEY_BASE",
        "value": "e1595bf08376c13f4494fa5c7ef65f3d547097113ceec483ed669387a44f716b09f12bedf2021c031fefb651cc0c8b4408cd8c24aab43e16cc1e7df6d18142d3"
      },
      {
        "name": "SEND_LIVE_COMMUNICATIONS",
        "value": "false"
      },
      {
        "name": "SENTRY_DSN",
        "value": "https://157a2d5f7d7441cbad977d92b21851ef:60c753947b834e0d87b8f0928df05eac@sentry.io/1276456"
      },
      {
        "name": "SIDEKIQ_PASSWORD",
        "value": "sideq-password"
      },
      {
        "name": "SIDEKIQ_USERNAME",
        "value": "developers"
      },
      {
        "name": "TENANCY_API_HOST",
        "value": "https://g6bw0g0ojk.execute-api.eu-west-2.amazonaws.com/staging/tenancy"
      },
      {
        "name": "TENANCY_API_KEY",
        "value": "api-key"
      },
      {
        "name": "TEST_EMAIL_ADDRESS",
        "value": "soraya.clarke@hackney.gov.uk"
      },
      {
        "name": "TEST_PHONE_NUMBER",
        "value": "07976662022"
      },
      {
        "name": "UH_DATABASE_HOST",
        "value": "10.80.65.4"
      },
      {
        "name": "UH_DATABASE_NAME",
        "value": "StagedDB"
      },
      {
        "name": "UH_DATABASE_PASSWORD",
        "value": "pwd"
      },
      {
        "name": "UH_DATABASE_PORT",
        "value": "1433"
      },
      {
        "name": "UH_DATABASE_USERNAME",
        "value": "HackneyAPIIncomeCollection"
      },
      {
        "name": "DATABASE_HOST",
        "value": "${data.aws_ssm_parameter.housing_finance_db_host.value}"
      },
      {
        "name": "DATABASE_USERNAME",
        "value": "${data.aws_ssm_parameter.housing_finance_db_username.value}"
      },
      {
        "name": "DATABASE_PASSWORD",
        "value": "${data.aws_ssm_parameter.housing_finance_db_password.value}"
      },
      {
        "name": "DATABASE_NAME",
        "value": "${data.aws_ssm_parameter.housing_finance_db_database.value}"
      }
    ]
  }
]
DEFINITION
}

# MySQL Database Setup
resource "aws_db_subnet_group" "db_subnets" {
  name       = "housing-finance-db-subnet-${var.environment_name}"
  subnet_ids = ["subnet-05ce390ba88c42bfd","subnet-0140d06fb84fdb547"]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "housing-mysql-db" {
  identifier                  = "housing-finance-db-${var.environment_name}"
  engine                      = "mysql"
  engine_version              = "8.0.20"
  instance_class              = "db.t2.micro" //this should be a more production appropriate instance in production
  allocated_storage           = 10
  storage_type                = "gp2" //ssd
  port                        = 3306
  backup_window               = "00:01-00:31"
  username                    = data.aws_ssm_parameter.housing_finance_db_username.value
  password                    = data.aws_ssm_parameter.housing_finance_db_password.value
  vpc_security_group_ids      = ["sg-00d2e14f38245dd0b"]
  db_subnet_group_name        = aws_db_subnet_group.db_subnets.name
  name                        = "housingfinancedb${var.environment_name}"
  monitoring_interval         = 0 //this is for enhanced Monitoring there will already be some basic monitoring available
  backup_retention_period     = 30
  storage_encrypted           = false  //this should be true for production
  deletion_protection         = false
  multi_az                    = false //this should be true for production
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false

  apply_immediately   = false
  skip_final_snapshot = true
  publicly_accessible = false

  tags = {
    Name              = "housing-finance-db-${var.environment_name}"
    Environment       = var.environment_name
    terraform-managed = true
    project_name      = "Housing Finance"
  }
}

# Network Load Balancer (NLB) setup

resource "aws_lb" "lb" {
  name               = "lb-${var.app_name}"
  internal           = true
  load_balancer_type = "network"
  subnets            = ["subnet-0140d06fb84fdb547", "subnet-05ce390ba88c42bfd"]// Get this from AWS (data)
  enable_deletion_protection = false
  tags = {
    Environment = var.environment_name
  }
}
resource "aws_lb_target_group" "lb_tg" {
  depends_on  = [
    aws_lb.lb
  ]
  name_prefix = "ma-tg-"
  port        = var.app_port
  protocol    = "TCP"
  vpc_id      = "vpc-0d15f152935c8716f" // Get this from AWS (data)
  target_type = "ip"
  stickiness {
    enabled = false
    type = "lb_cookie"
  }
  lifecycle {
    create_before_destroy = true
  }
}
# Redirect all traffic from the NLB to the target group
resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb.id
  port              = var.app_port
  protocol    = "TCP"
  default_action {
    target_group_arn = aws_lb_target_group.lb_tg.id
    type             = "forward"
  }
}

# API Gateway setup

# VPC Link
resource "aws_api_gateway_vpc_link" "this" {
  name = "vpc-link-${var.app_name}"
  target_arns = [aws_lb.lb.arn]
}
# API Gateway, Private Integration with VPC Link
# and deployment of a single resource that will take ANY
# HTTP method and proxy the request to the NLB
resource "aws_api_gateway_rest_api" "main" {
  name = "${var.environment_name}-${var.app_name}"
}
resource "aws_api_gateway_resource" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  parent_id   = aws_api_gateway_rest_api.main.root_resource_id
  path_part   = "{proxy+}"
}
resource "aws_api_gateway_method" "main" {
  rest_api_id   = aws_api_gateway_rest_api.main.id
  resource_id   = aws_api_gateway_resource.main.id
  http_method   = "ANY"
  authorization = "NONE"
  request_parameters = {
    "method.request.path.proxy" = true
    "method.request.header.Authorization" = false
  }
}
resource "aws_api_gateway_integration" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  resource_id = aws_api_gateway_resource.main.id
  http_method = aws_api_gateway_method.main.http_method
  request_parameters = {
    "integration.request.path.proxy" = "method.request.path.proxy"
  }
  type                    = "HTTP_PROXY"
  uri                     = "http://${aws_lb.lb.dns_name}:${var.app_port}/{proxy}"
  integration_http_method = "ANY"
  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.this.id
}
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name = var.environment_name
  depends_on = [aws_api_gateway_integration.main]
  variables = {
    # just to trigger redeploy on resource changes
    resources = join(", ", [aws_api_gateway_resource.main.id])
    # note: redeployment might be required with other gateway changes.
    # when necessary run `terraform taint <this resource's address>`
  }
  lifecycle {
    create_before_destroy = true
  }
}
