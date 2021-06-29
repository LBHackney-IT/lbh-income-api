provider "aws" {
  region  = "eu-west-2"
}
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}
locals {
  application_name = "lbh income api"
  parameter_store = "arn:aws:ssm:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:parameter"
}

# SSM Parameters - Systems Manager/Parameter Store
data "aws_ssm_parameter" "housing_finance_docs_bucket" {
  name = "/housing-finance/production/docs-bucket"
}
data "aws_ssm_parameter" "housing_finance_db_host" {
  name = "/housing-finance/production/uh-database-host"
}
data "aws_ssm_parameter" "housing_finance_db_port" {
  name = "/housing-finance/production/uh-database-port"
}
data "aws_ssm_parameter" "housing_finance_db_database" {
  name = "/housing-finance/production/uh-database-name"
}
data "aws_ssm_parameter" "housing_finance_db_username" {
  name = "/housing-finance/production/uh-database-username"
}
data "aws_ssm_parameter" "housing_finance_db_password" {
  name = "/housing-finance/production/uh-database-password"
}
data "aws_ssm_parameter" "housing_finance_mysql_host" {
  name = "/housing-finance/production/mysql-host"
}
data "aws_ssm_parameter" "housing_finance_mysql_database" {
  name = "/housing-finance/production/mysql-database"
}
data "aws_ssm_parameter" "housing_finance_mysql_username" {
  name = "/housing-finance/production/mysql-username"
}
data "aws_ssm_parameter" "housing_finance_mysql_password" {
  name = "/housing-finance/production/mysql-password"
}
data "aws_ssm_parameter" "housing_finance_aws_access_key_id" {
  name = "/housing-finance/production/aws-access-key-id"
}
data "aws_ssm_parameter" "housing_finance_aws_region" {
  name = "/housing-finance/production/aws-region"
}
data "aws_ssm_parameter" "housing_finance_aws_secret_access_key" {
  name = "/housing-finance/production/aws-secret-access-key"
}
data "aws_ssm_parameter" "housing_finance_automate_income_collection_letter_one" {
  name = "/housing-finance/production/automate-income-collection-letter-one"
}
data "aws_ssm_parameter" "housing_finance_automate_income_collection_letter_two" {
  name = "/housing-finance/production/automate-income-collection-letter-two"
}
data "aws_ssm_parameter" "housing_finance_automate_income_collection_sms" {
  name = "/housing-finance/production/automate-income-collection-sms"
}
data "aws_ssm_parameter" "housing_finance_can_automate_letters" {
  name = "/housing-finance/production/can-automate-letters"
}
data "aws_ssm_parameter" "housing_finance_customer_managed_key" {
  name = "/housing-finance/production/customer-managed-key"
}
data "aws_ssm_parameter" "housing_finance_database_url" {
  name = "/housing-finance/production/database-url"
}
data "aws_ssm_parameter" "housing_finance_enable_tenancy_sync" {
  name = "/housing-finance/production/enable-tenancy-sync"
}
data "aws_ssm_parameter" "housing_finance_gov_notify_api_key" {
  name = "/housing-finance/production/gov-notify-api-key"
}
data "aws_ssm_parameter" "housing_finance_gov_notify_sender_id" {
  name = "/housing-finance/production/gov-notify-sender-id"
}
data "aws_ssm_parameter" "housing_finance_hardcoded_tenancies" {
  name = "/housing-finance/production/hardcoded-tenancies"
}
data "aws_ssm_parameter" "housing_finance_new_relic_env" {
  name = "/housing-finance/production/new-relic-env"
}
data "aws_ssm_parameter" "housing_finance_patch_codes_for_letter_automation" {
  name = "/housing-finance/production/patch-codes-for-letter-automation"
}
data "aws_ssm_parameter" "housing_finance_restrict_patches" {
  name = "/housing-finance/production/restrict-patches"
}
data "aws_ssm_parameter" "housing_finance_permitted_patches" {
  name = "/housing-finance/production/permitted-patches"
}
data "aws_ssm_parameter" "housing_finance_patch_codes_for_sms_automation" {
  name = "/housing-finance/production/patch-codes-for-sms-automation"
}
data "aws_ssm_parameter" "housing_finance_rack_env" {
  name = "/housing-finance/production/rack-env"
}
data "aws_ssm_parameter" "housing_finance_rails_env" {
  name = "/housing-finance/production/rails-env"
}
data "aws_ssm_parameter" "housing_finance_rails_log_to_stdout" {
  name = "/housing-finance/production/rails-log-to-stdout"
}
data "aws_ssm_parameter" "housing_finance_redis_url" {
  name = "/housing-finance/production/redis-url"
}
data "aws_ssm_parameter" "housing_finance_secret_key_base" {
  name = "/housing-finance/production/secret-key-base"
}
data "aws_ssm_parameter" "housing_finance_send_live_communications" {
  name = "/housing-finance/production/send-live-communications"
}
data "aws_ssm_parameter" "housing_finance_sentry_dsn" {
  name = "/housing-finance/production/sentry-dsn"
}
data "aws_ssm_parameter" "housing_finance_sentry_environment" {
  name = "/housing-finance/production/sentry-environment"
}
data "aws_ssm_parameter" "housing_finance_sidekiq_password" {
  name = "/housing-finance/production/sidekiq-password"
}
data "aws_ssm_parameter" "housing_finance_sidekiq_username" {
  name = "/housing-finance/production/sidekiq-username"
}
data "aws_ssm_parameter" "housing_finance_tenancy_api_host" {
  name = "/housing-finance/production/tenancy-api-host"
}
data "aws_ssm_parameter" "housing_finance_tenancy_api_key" {
  name = "/housing-finance/production/tenancy-api-key"
}
data "aws_ssm_parameter" "housing_finance_test_email_address" {
  name = "/housing-finance/production/test-email-address"
}
data "aws_ssm_parameter" "housing_finance_test_phone_number" {
  name = "/housing-finance/production/test-phone-number"
}

# Terraform State Management
terraform {
  backend "s3" {
    bucket  = "terraform-state-housing-production"
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
    subnets          = ["subnet-0beb266003a56ca82","subnet-06a697d86a9b6ed01"]
    security_groups = ["sg-01396d0029aa1c950"]
    assign_public_ip = false
  }
  desired_count = 1
  load_balancer {
    target_group_arn = aws_lb_target_group.lb_tg.arn
    container_name   = "income-api-container"
    container_port   = 3000
  }
}

resource "aws_ecs_task_definition" "income-api-ecs-task-definition" {
  family                   = "ecs-task-definition-income-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  memory                   = "4096"
  cpu                      = "1024"
  execution_role_arn       = "arn:aws:iam::282997303675:role/ecsTaskExecutionRole"
  container_definitions    = <<DEFINITION
[
  {
    "name": "income-api-container",
    "image": "282997303675.dkr.ecr.eu-west-2.amazonaws.com/hackney/apps/income-api:${var.sha1}",
    "memory": 1024,
    "cpu": 512,
    "essential": true,
    "portMappings": [
      {
        "containerPort": 3000
      }
    ],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "ecs-task-definition-income-api",
            "awslogs-region": "eu-west-2",
            "awslogs-stream-prefix": "income-api-logs"
        }
    },
    "environment": [
      {
        "name": "HOUSING_DOCS_BUCKET",
        "value": "${data.aws_ssm_parameter.housing_finance_docs_bucket.value}"
      },
      {
        "name": "CUSTOMER_MANAGED_KEY",
        "value": "${data.aws_ssm_parameter.housing_finance_customer_managed_key.value}"
      },
      {
        "name": "AWS_ACCESS_KEY_ID",
        "value": "${data.aws_ssm_parameter.housing_finance_aws_access_key_id.value}"
      },
      {
        "name": "AWS_SECRET_ACCESS_KEY",
        "value": "${data.aws_ssm_parameter.housing_finance_aws_secret_access_key.value}"
      },
      {
        "name": "AUTOMATE_INCOME_COLLECTION_LETTER_ONE",
        "value": "${data.aws_ssm_parameter.housing_finance_automate_income_collection_letter_one.value}"
      },
      {
        "name": "AUTOMATE_INCOME_COLLECTION_LETTER_TWO",
        "value": "${data.aws_ssm_parameter.housing_finance_automate_income_collection_letter_two.value}"
      },
      {
        "name": "AWS_REGION",
        "value": "${data.aws_ssm_parameter.housing_finance_aws_region.value}"
      },
      {
        "name": "CAN_AUTOMATE_LETTERS",
        "value": "${data.aws_ssm_parameter.housing_finance_can_automate_letters.value}"
      },
      {
        "name": "ENABLE_TENANCY_SYNC",
        "value": "${data.aws_ssm_parameter.housing_finance_enable_tenancy_sync.value}"
      },
      {
        "name": "GOV_NOTIFY_API_KEY",
        "value": "${data.aws_ssm_parameter.housing_finance_gov_notify_api_key.value}"
      },
      {
        "name": "GOV_NOTIFY_SENDER_ID",
        "value": "${data.aws_ssm_parameter.housing_finance_gov_notify_sender_id.value}"
      },
      {
        "name": "HARDCODED_TENANCIES",
        "value": "${data.aws_ssm_parameter.housing_finance_hardcoded_tenancies.value}"
      },
      {
        "name": "PATCH_CODES_FOR_LETTER_AUTOMATION",
        "value": "${data.aws_ssm_parameter.housing_finance_patch_codes_for_letter_automation.value}"
      },
      {
        "name": "RACK_ENV",
        "value": "${data.aws_ssm_parameter.housing_finance_rack_env.value}"
      },
      {
        "name": "RAILS_ENV",
        "value": "${data.aws_ssm_parameter.housing_finance_rails_env.value}"
      },
      {
        "name": "RAILS_LOG_TO_STDOUT",
        "value": "${data.aws_ssm_parameter.housing_finance_rails_log_to_stdout.value}"
      },
      {
        "name": "REDIS_URL",
        "value": "${data.aws_ssm_parameter.housing_finance_redis_url.value}"
      },
      {
        "name": "SECRET_KEY_BASE",
        "value": "${data.aws_ssm_parameter.housing_finance_secret_key_base.value}"
      },
      {
        "name": "SEND_LIVE_COMMUNICATIONS",
        "value": "${data.aws_ssm_parameter.housing_finance_send_live_communications.value}"
      },
      {
        "name": "SENTRY_DSN",
        "value": "${data.aws_ssm_parameter.housing_finance_sentry_dsn.value}"
      },
      {
        "name": "SIDEKIQ_PASSWORD",
        "value": "${data.aws_ssm_parameter.housing_finance_sidekiq_password.value}"
      },
      {
        "name": "SIDEKIQ_USERNAME",
        "value": "${data.aws_ssm_parameter.housing_finance_sidekiq_username.value}"
      },
      {
        "name": "TENANCY_API_HOST",
        "value": "${data.aws_ssm_parameter.housing_finance_tenancy_api_host.value}"
      },
      {
        "name": "TENANCY_API_KEY",
        "value": "${data.aws_ssm_parameter.housing_finance_tenancy_api_key.value}"
      },
      {
        "name": "TEST_EMAIL_ADDRESS",
        "value": "${data.aws_ssm_parameter.housing_finance_test_email_address.value}"
      },
      {
        "name": "TEST_PHONE_NUMBER",
        "value": "${data.aws_ssm_parameter.housing_finance_test_phone_number.value}"
      },
      {
        "name": "UH_DATABASE_HOST",
        "value": "${data.aws_ssm_parameter.housing_finance_db_host.value}"
      },
      {
        "name": "UH_DATABASE_NAME",
        "value": "${data.aws_ssm_parameter.housing_finance_db_database.value}"
      },
      {
        "name": "UH_DATABASE_PASSWORD",
        "value": "${data.aws_ssm_parameter.housing_finance_db_password.value}"
      },
      {
        "name": "UH_DATABASE_PORT",
        "value": "${data.aws_ssm_parameter.housing_finance_db_port.value}"
      },
      {
        "name": "UH_DATABASE_USERNAME",
        "value": "${data.aws_ssm_parameter.housing_finance_db_username.value}"
      },
      {
        "name": "DATABASE_HOST",
        "value": "${data.aws_ssm_parameter.housing_finance_mysql_host.value}"
      },
      {
        "name": "DATABASE_USERNAME",
        "value": "${data.aws_ssm_parameter.housing_finance_mysql_username.value}"
      },
      {
        "name": "DATABASE_PASSWORD",
        "value": "${data.aws_ssm_parameter.housing_finance_mysql_password.value}"
      },
      {
        "name": "DATABASE_NAME",
        "value": "${data.aws_ssm_parameter.housing_finance_mysql_database.value}"
      },
      {
        "name": "DATABASE_URL",
        "value": "${data.aws_ssm_parameter.housing_finance_database_url.value}"
      }
    ]
  },
  {
    "name": "income-api-worker-container",
    "image": "282997303675.dkr.ecr.eu-west-2.amazonaws.com/hackney/apps/income-api:${var.sha1}",
    "memory": 2048,
    "cpu": 512,
    "essential": true,
    "command": ["sh","-c","sidekiq -C ./schedule.yml & sidekiq"],
    "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
            "awslogs-group": "ecs-task-definition-income-api-worker",
            "awslogs-region": "eu-west-2",
            "awslogs-stream-prefix": "income-api-worker-logs"
        }
    },
    "environment": [
      {
        "name": "HOUSING_DOCS_BUCKET",
        "value": "${data.aws_ssm_parameter.housing_finance_docs_bucket.value}"
      },
      {
        "name": "AUTOMATE_INCOME_COLLECTION_LETTER_ONE",
        "value": "${data.aws_ssm_parameter.housing_finance_automate_income_collection_letter_one.value}"
      },
      {
        "name": "AUTOMATE_INCOME_COLLECTION_LETTER_TWO",
        "value": "${data.aws_ssm_parameter.housing_finance_automate_income_collection_letter_two.value}"
      },
      {
        "name": "AUTOMATE_INCOME_COLLECTION_SMS",
        "value": "${data.aws_ssm_parameter.housing_finance_automate_income_collection_sms.value}"
      },
      {
        "name": "CUSTOMER_MANAGED_KEY",
        "value": "${data.aws_ssm_parameter.housing_finance_customer_managed_key.value}"
      },
      {
        "name": "AWS_ACCESS_KEY_ID",
        "value": "${data.aws_ssm_parameter.housing_finance_aws_access_key_id.value}"
      },
      {
        "name": "AWS_SECRET_ACCESS_KEY",
        "value": "${data.aws_ssm_parameter.housing_finance_aws_secret_access_key.value}"
      },
      {
        "name": "AWS_REGION",
        "value": "${data.aws_ssm_parameter.housing_finance_aws_region.value}"
      },
      {
        "name": "CAN_AUTOMATE_LETTERS",
        "value": "${data.aws_ssm_parameter.housing_finance_can_automate_letters.value}"
      },
      {
        "name": "ENABLE_TENANCY_SYNC",
        "value": "${data.aws_ssm_parameter.housing_finance_enable_tenancy_sync.value}"
      },
      {
        "name": "GOV_NOTIFY_API_KEY",
        "value": "${data.aws_ssm_parameter.housing_finance_gov_notify_api_key.value}"
      },
      {
        "name": "GOV_NOTIFY_SENDER_ID",
        "value": "${data.aws_ssm_parameter.housing_finance_gov_notify_sender_id.value}"
      },
      {
        "name": "HARDCODED_TENANCIES",
        "value": "${data.aws_ssm_parameter.housing_finance_hardcoded_tenancies.value}"
      },
      {
        "name": "PATCH_CODES_FOR_LETTER_AUTOMATION",
        "value": "${data.aws_ssm_parameter.housing_finance_patch_codes_for_letter_automation.value}"
      },
      {
        "name": "PATCH_CODES_FOR_SMS_AUTOMATION",
        "value": "${data.aws_ssm_parameter.housing_finance_patch_codes_for_sms_automation.value}"
      },
      {
        "name": "PERMITTED_PATCHES",
        "value": "${data.aws_ssm_parameter.housing_finance_permitted_patches.value}"
      },
      {
        "name": "RACK_ENV",
        "value": "${data.aws_ssm_parameter.housing_finance_rack_env.value}"
      },
      {
        "name": "RAILS_ENV",
        "value": "${data.aws_ssm_parameter.housing_finance_rails_env.value}"
      },
      {
        "name": "RAILS_LOG_TO_STDOUT",
        "value": "${data.aws_ssm_parameter.housing_finance_rails_log_to_stdout.value}"
      },
      {
        "name": "REDIS_URL",
        "value": "${data.aws_ssm_parameter.housing_finance_redis_url.value}"
      },
      {
        "name": "RESTRICT_PATCHES",
        "value": "${data.aws_ssm_parameter.housing_finance_restrict_patches.value}"
      },
      {
        "name": "SECRET_KEY_BASE",
        "value": "${data.aws_ssm_parameter.housing_finance_secret_key_base.value}"
      },
      {
        "name": "SEND_LIVE_COMMUNICATIONS",
        "value": "${data.aws_ssm_parameter.housing_finance_send_live_communications.value}"
      },
      {
        "name": "SENTRY_DSN",
        "value": "${data.aws_ssm_parameter.housing_finance_sentry_dsn.value}"
      },
      {
        "name": "TENANCY_API_HOST",
        "value": "${data.aws_ssm_parameter.housing_finance_tenancy_api_host.value}"
      },
      {
        "name": "TENANCY_API_KEY",
        "value": "${data.aws_ssm_parameter.housing_finance_tenancy_api_key.value}"
      },
      {
        "name": "TEST_EMAIL_ADDRESS",
        "value": "${data.aws_ssm_parameter.housing_finance_test_email_address.value}"
      },
      {
        "name": "TEST_PHONE_NUMBER",
        "value": "${data.aws_ssm_parameter.housing_finance_test_phone_number.value}"
      },
      {
        "name": "UH_DATABASE_HOST",
        "value": "${data.aws_ssm_parameter.housing_finance_db_host.value}"
      },
      {
        "name": "UH_DATABASE_NAME",
        "value": "${data.aws_ssm_parameter.housing_finance_db_database.value}"
      },
      {
        "name": "UH_DATABASE_PASSWORD",
        "value": "${data.aws_ssm_parameter.housing_finance_db_password.value}"
      },
      {
        "name": "UH_DATABASE_PORT",
        "value": "${data.aws_ssm_parameter.housing_finance_db_port.value}"
      },
      {
        "name": "UH_DATABASE_USERNAME",
        "value": "${data.aws_ssm_parameter.housing_finance_db_username.value}"
      },
      {
        "name": "DATABASE_HOST",
        "value": "${data.aws_ssm_parameter.housing_finance_mysql_host.value}"
      },
      {
        "name": "DATABASE_USERNAME",
        "value": "${data.aws_ssm_parameter.housing_finance_mysql_username.value}"
      },
      {
        "name": "DATABASE_PASSWORD",
        "value": "${data.aws_ssm_parameter.housing_finance_mysql_password.value}"
      },
      {
        "name": "DATABASE_NAME",
        "value": "${data.aws_ssm_parameter.housing_finance_mysql_database.value}"
      },
      {
        "name": "DATABASE_URL",
        "value": "${data.aws_ssm_parameter.housing_finance_database_url.value}"
      }
    ]
  }
]
DEFINITION
}

# Network Load Balancer (NLB) setup
resource "aws_lb" "lb" {
  name               = "lb-income-api"
  internal           = true
  load_balancer_type = "network"
  subnets            = ["subnet-0beb266003a56ca82","subnet-06a697d86a9b6ed01"]
  enable_deletion_protection = false
  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "lb_tg" {
  depends_on  = [
    aws_lb.lb
  ]
  name_prefix = "ma-tg-"
  port        = 3000
  protocol    = "TCP"
  vpc_id      = "vpc-0ce853ddb64e8fb3c"
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
  port              = 3000
  protocol    = "TCP"
  default_action {
    target_group_arn = aws_lb_target_group.lb_tg.id
    type             = "forward"
  }
}

# API Gateway setup
# VPC Link
resource "aws_api_gateway_vpc_link" "this" {
  name = "vpc-link-income-api"
  target_arns = [aws_lb.lb.arn]
}
# API Gateway, Private Integration with VPC Link
# and deployment of a single resource that will take ANY
# HTTP method and proxy the request to the NLB
resource "aws_api_gateway_rest_api" "main" {
  name = "production-income-api"
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
  api_key_required = true
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
  uri                     = "http://${aws_lb.lb.dns_name}:3000/{proxy}"
  integration_http_method = "ANY"
  connection_type = "VPC_LINK"
  connection_id   = aws_api_gateway_vpc_link.this.id
}
resource "aws_api_gateway_deployment" "main" {
  rest_api_id = aws_api_gateway_rest_api.main.id
  stage_name = "production"
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

resource "aws_api_gateway_usage_plan" "main" {
  name = "income_api_production_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_deployment.main.stage_name
  }
}

resource "aws_api_gateway_api_key" "main" {
  name = "income_api_production_key"
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.main.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}
