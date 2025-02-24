################################################################################
# MkDocs image builder
################################################################################

module "aws_ecrbuild" {
  source = "tfstack/ecrbuild/aws"

  region = local.region

  # Naming & Resource Identifiers
  repository_name         = local.name
  app_name                = local.app_name
  suffix                  = random_string.suffix.result
  repository_force_delete = true

  # Application & Storage Configuration
  container_source_path  = "${path.module}/external/source"
  container_archive_path = "${path.module}/external"
  log_retention_days     = 30

  # CodeBuild Configuration
  codebuild_timeout          = 10
  codebuild_compute_type     = "BUILD_GENERAL1_SMALL"
  codebuild_image            = "aws/codebuild/standard:5.0"
  codebuild_environment_type = "LINUX_CONTAINER"
  codebuild_buildspec        = "buildspec.yml"

  codebuild_env_vars = {
    ENVIRONMENT = "dev"
    PROJECT     = "example-project"
  }

  # CodePipeline Configuration
  codepipeline_stages = [
    {
      name = "Source"
      actions = [
        {
          name             = "S3-Source"
          category         = "Source"
          owner            = "AWS"
          provider         = "S3"
          version          = "1"
          output_artifacts = ["source-output"]
          configuration = {
            S3Bucket             = local.base_name
            S3ObjectKey          = "${local.app_name}.zip"
            PollForSourceChanges = "true"
          }
        }
      ]
    },
    {
      name = "Build"
      actions = [
        {
          name            = "Build-Docker-Image"
          category        = "Build"
          owner           = "AWS"
          provider        = "CodeBuild"
          version         = "1"
          input_artifacts = ["source-output"]
          configuration = {
            ProjectName = local.base_name
          }
        }
      ]
    }
  ]

  # Tags
  tags = {
    Environment = "dev"
    Project     = "example-project"
  }
}
