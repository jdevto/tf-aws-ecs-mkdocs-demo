################################################################################
# ECS
################################################################################

resource "aws_iam_policy" "mkdocs" {
  name        = "${local.base_name}-mkdocs"
  description = "Allows CodeBuild to build and push images to ECR."

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "ECRAuthAccess"
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken"
        ]
        Resource = "*"
      },
      {
        Sid    = "ECRReadOnlyAccess"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:GetDownloadUrlForLayer"
        ]
        Resource = module.aws_ecrbuild.ecr_repository_arn
      },
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = [
          for log_group in aws_cloudwatch_log_group.mkdocs : "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${log_group.name}:*"
        ]
      }
    ]
  })
}

module "ecs" {
  source = "tfstack/ecs-cluster-classic/aws"

  # Core Configuration
  cluster_name            = local.name
  enable_cloudwatch_agent = true
  security_group_ids      = [module.vpc.eic_security_group_id]

  # VPC Configuration
  vpc = {
    id = module.vpc.vpc_id
    private_subnets = [
      for i, subnet in module.vpc.private_subnet_ids :
      { id = subnet, cidr = module.vpc.private_subnet_cidrs[i] }
    ]
  }

  # Auto Scaling Groups
  autoscaling_groups = [
    {
      name                  = "cluster1"
      min_size              = 3
      max_size              = 6
      desired_capacity      = 3
      image_id              = data.aws_ami.ecs_optimized.id
      instance_type         = "t3a.medium"
      ebs_optimized         = true
      protect_from_scale_in = false

      additional_iam_policies = [
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]

      # Tags
      tag_specifications = [
        {
          resource_type = "instance"
          tags = {
            Environment = "dev"
            Name        = "instance-1"
          }
        }
      ]

      # User Data
      user_data = templatefile("${path.module}/external/ecs.sh.tpl", {
        cluster_name = local.name
      })
    }
  ]

  ecs_services = [
    {
      name          = "mkdocs-1"
      desired_count = 3
      cpu           = 256
      memory        = 512

      execution_role_policies = [
        aws_iam_policy.mkdocs.arn
      ]

      container_definitions = jsonencode([
        {
          name         = "mkdocs-1"
          image        = "${module.aws_ecrbuild.ecr_repository_url}:latest"
          cpu          = 256
          memory       = 512
          essential    = true
          portMappings = [{ containerPort = 8000, hostPort = 8001 }]

          healthCheck = {
            command     = ["CMD-SHELL", "curl -f http://0.0.0.0:8000 || exit 1"]
            interval    = 30
            timeout     = 5
            retries     = 3
            startPeriod = 10
          }

          logConfiguration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = "/ecs/${local.name}/mkdocs-1"
              awslogs-region        = local.region
              awslogs-stream-prefix = local.app_name
            }
          }
        }
      ])

      service_tags = {
        "Environment" = "dev"
        "Project"     = "Documentation"
        "Owner"       = "DevOps Team"
      }
      task_tags = {
        "TaskType" = "mkdocs-rendering"
        "Version"  = "1.0"
      }
      enable_ecs_managed_tags = true
      propagate_tags          = "TASK_DEFINITION"
    },
    {
      name          = "mkdocs-2"
      desired_count = 1
      cpu           = 256
      memory        = 512

      execution_role_policies = [
        aws_iam_policy.mkdocs.arn
      ]

      container_definitions = jsonencode([
        {
          name         = "mkdocs-2"
          image        = "${module.aws_ecrbuild.ecr_repository_url}:latest"
          cpu          = 256
          memory       = 512
          essential    = true
          portMappings = [{ containerPort = 8000, hostPort = 8002 }]

          healthCheck = {
            command     = ["CMD-SHELL", "curl -f http://0.0.0.0:8000 || exit 1"]
            interval    = 30
            timeout     = 5
            retries     = 3
            startPeriod = 10
          }

          logConfiguration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = "/ecs/${local.name}/mkdocs-2"
              awslogs-region        = local.region
              awslogs-stream-prefix = local.app_name
            }
          }
        }
      ])
    },
    {
      name          = "mkdocs-3"
      desired_count = 1
      cpu           = 256
      memory        = 512

      execution_role_policies = [
        aws_iam_policy.mkdocs.arn
      ]

      container_definitions = jsonencode([
        {
          name         = "mkdocs-3"
          image        = "${module.aws_ecrbuild.ecr_repository_url}:latest"
          cpu          = 256
          memory       = 512
          essential    = true
          portMappings = [{ containerPort = 8000, hostPort = 8003 }]

          healthCheck = {
            command     = ["CMD-SHELL", "curl -f http://0.0.0.0:8000 || exit 1"]
            interval    = 30
            timeout     = 5
            retries     = 3
            startPeriod = 10
          }

          logConfiguration = {
            logDriver = "awslogs"
            options = {
              awslogs-group         = "/ecs/${local.name}/mkdocs-3"
              awslogs-region        = local.region
              awslogs-stream-prefix = local.app_name
            }
          }
        }
      ])
    }
  ]
}

resource "aws_cloudwatch_log_group" "mkdocs" {
  for_each = toset(["mkdocs-1", "mkdocs-2", "mkdocs-3"])

  name              = "/ecs/${local.name}/${each.key}"
  retention_in_days = 1

  lifecycle {
    prevent_destroy = false
  }
}
