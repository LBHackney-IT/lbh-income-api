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
  name = "/housing-finance/development/docs-bucket"
}
data "aws_ssm_parameter" "housing_finance_db_host" {
  name = "/housing-finance/development/uh-database-host"
}
data "aws_ssm_parameter" "housing_finance_db_port" {
  name = "/housing-finance/development/uh-database-port"
}
data "aws_ssm_parameter" "housing_finance_db_database" {
  name = "/housing-finance/development/uh-database-name"
}
data "aws_ssm_parameter" "housing_finance_db_username" {
  name = "/housing-finance/development/uh-database-username"
}
data "aws_ssm_parameter" "housing_finance_db_password" {
  name = "/housing-finance/development/uh-database-password"
}
data "aws_ssm_parameter" "housing_finance_mysql_host" {
  name = "/housing-finance/development/mysql-host"
}
data "aws_ssm_parameter" "housing_finance_mysql_database" {
  name = "/housing-finance/development/mysql-database"
}
data "aws_ssm_parameter" "housing_finance_mysql_username" {
  name = "/housing-finance/development/mysql-username"
}
data "aws_ssm_parameter" "housing_finance_mysql_password" {
  name = "/housing-finance/development/mysql-password"
}
data "aws_ssm_parameter" "housing_finance_aws_access_key_id" {
  name = "/housing-finance/development/aws-access-key-id"
}
data "aws_ssm_parameter" "housing_finance_aws_region" {
  name = "/housing-finance/development/aws-region"
}
data "aws_ssm_parameter" "housing_finance_aws_secret_access_key" {
  name = "/housing-finance/development/aws-secret-access-key"
}
data "aws_ssm_parameter" "housing_finance_automate_income_collection_letter_one" {
  name = "/housing-finance/development/automate-income-collection-letter-one"
}
data "aws_ssm_parameter" "housing_finance_automate_income_collection_letter_two" {
  name = "/housing-finance/development/automate-income-collection-letter-two"
}
data "aws_ssm_parameter" "housing_finance_automate_income_collection_sms" {
  name = "/housing-finance/development/automate-income-collection-sms"
}
data "aws_ssm_parameter" "housing_finance_can_automate_letters" {
  name = "/housing-finance/development/can-automate-letters"
}
data "aws_ssm_parameter" "housing_finance_customer_managed_key" {
  name = "/housing-finance/development/customer-managed-key"
}
data "aws_ssm_parameter" "housing_finance_database_url" {
  name = "/housing-finance/development/database-url"
}
data "aws_ssm_parameter" "housing_finance_enable_tenancy_sync" {
  name = "/housing-finance/development/enable-tenancy-sync"
}
data "aws_ssm_parameter" "housing_finance_gov_notify_api_key" {
  name = "/housing-finance/development/gov-notify-api-key"
}
data "aws_ssm_parameter" "housing_finance_gov_notify_sender_id" {
  name = "/housing-finance/development/gov-notify-sender-id"
}
data "aws_ssm_parameter" "housing_finance_hardcoded_tenancies" {
  name = "/housing-finance/development/hardcoded-tenancies"
}
data "aws_ssm_parameter" "housing_finance_new_relic_env" {
  name = "/housing-finance/development/new-relic-env"
}
data "aws_ssm_parameter" "housing_finance_patch_codes_for_letter_automation" {
  name = "/housing-finance/development/patch-codes-for-letter-automation"
}
data "aws_ssm_parameter" "housing_finance_restrict_patches" {
  name = "/housing-finance/development/restrict-patches"
}
data "aws_ssm_parameter" "housing_finance_permitted_patches" {
  name = "/housing-finance/development/permitted-patches"
}
data "aws_ssm_parameter" "housing_finance_patch_codes_for_sms_automation" {
  name = "/housing-finance/development/patch-codes-for-sms-automation"
}
data "aws_ssm_parameter" "housing_finance_rack_env" {
  name = "/housing-finance/development/rack-env"
}
data "aws_ssm_parameter" "housing_finance_rails_env" {
  name = "/housing-finance/development/rails-env"
}
data "aws_ssm_parameter" "housing_finance_rails_log_to_stdout" {
  name = "/housing-finance/development/rails-log-to-stdout"
}
data "aws_ssm_parameter" "housing_finance_redis_url" {
  name = "/housing-finance/development/redis-url"
}
data "aws_ssm_parameter" "housing_finance_secret_key_base" {
  name = "/housing-finance/development/secret-key-base"
}
data "aws_ssm_parameter" "housing_finance_send_live_communications" {
  name = "/housing-finance/development/send-live-communications"
}
data "aws_ssm_parameter" "housing_finance_sentry_dsn" {
  name = "/housing-finance/development/sentry-dsn"
}
data "aws_ssm_parameter" "housing_finance_sentry_environment" {
  name = "/housing-finance/development/sentry-environment"
}
data "aws_ssm_parameter" "housing_finance_sidekiq_password" {
  name = "/housing-finance/development/sidekiq-password"
}
data "aws_ssm_parameter" "housing_finance_sidekiq_username" {
  name = "/housing-finance/development/sidekiq-username"
}
data "aws_ssm_parameter" "housing_finance_tenancy_api_host" {
  name = "/housing-finance/development/tenancy-api-host"
}
data "aws_ssm_parameter" "housing_finance_tenancy_api_key" {
  name = "/housing-finance/development/tenancy-api-key"
}
data "aws_ssm_parameter" "housing_finance_test_email_address" {
  name = "/housing-finance/development/test-email-address"
}
data "aws_ssm_parameter" "housing_finance_test_phone_number" {
  name = "/housing-finance/development/test-phone-number"
}

# Terraform State Management
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
    execution_role_arn       = "arn:aws:iam::364864573329:role/ecsTaskExecutionRole"
    container_definitions    = <<DEFINITION
[
  {
    "name": "income-api-container",
    "image": "364864573329.dkr.ecr.eu-west-2.amazonaws.com/hackney/apps/income-api:${var.sha1}",
    "memory": 2048,
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
    "image": "364864573329.dkr.ecr.eu-west-2.amazonaws.com/hackney/apps/income-api:${var.sha1}",
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

# MySQL Database Setup
resource "aws_db_subnet_group" "db_subnets" {
  name       = "housing-finance-db-subnet-development"
  subnet_ids = ["subnet-05ce390ba88c42bfd","subnet-0140d06fb84fdb547"]
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "housing-mysql-db" {
  identifier                  = "housing-finance-db-development"
  engine                      = "mysql"
  engine_version              = "8.0.20"
  instance_class              = "db.t2.micro" //this should be a more production appropriate instance in production
  allocated_storage           = 10
  storage_type                = "gp2" //ssd
  port                        = 3306
  backup_window               = "00:01-00:31"
  username                    = data.aws_ssm_parameter.housing_finance_mysql_username.value
  password                    = data.aws_ssm_parameter.housing_finance_mysql_password.value
  vpc_security_group_ids      = ["sg-00d2e14f38245dd0b"]
  db_subnet_group_name        = aws_db_subnet_group.db_subnets.name
  name                        = data.aws_ssm_parameter.housing_finance_mysql_database.value
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
    Name              = "housing-finance-db-development"
    Environment       = "development"
    terraform-managed = true
    project_name      = "Housing Finance"
  }
}

# Network Load Balancer (NLB) setup
resource "aws_lb" "lb" {
  name               = "lb-income-api"
  internal           = true
  load_balancer_type = "network"
  subnets            = ["subnet-0140d06fb84fdb547", "subnet-05ce390ba88c42bfd"]// Get this from AWS (data)
  enable_deletion_protection = false
  tags = {
    Environment = "development"
  }
}

resource "aws_lb_target_group" "lb_tg" {
  depends_on  = [
    aws_lb.lb
  ]
  name_prefix = "ma-tg-"
  port        = 3000
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
  name = "development-income-api"
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
  stage_name = "development"
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
  name = "income_api_development_usage_plan"

  api_stages {
    api_id = aws_api_gateway_rest_api.main.id
    stage  = aws_api_gateway_deployment.main.stage_name
  }
}

resource "aws_api_gateway_api_key" "main" {
  name = "income_api_development_key"
}

resource "aws_api_gateway_usage_plan_key" "main" {
  key_id        = aws_api_gateway_api_key.main.id
  key_type      = "API_KEY"
  usage_plan_id = aws_api_gateway_usage_plan.main.id
}
