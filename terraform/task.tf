
resource "aws_batch_compute_environment" "fargate_environment" {
  compute_environment_name = "${var.project}-compute-environment"

  compute_resources {
    max_vcpus = 4
    security_group_ids = [
      aws_security_group.security.id
    ]
    subnets = [
      aws_subnet.subnet.id
    ]
    type = "FARGATE"
  }

  service_role = aws_iam_role.aws_batch_service_role.arn
  type         = "MANAGED"
  depends_on   = [aws_iam_role_policy_attachment.aws_batch_service_role]
}

resource "aws_batch_job_queue" "queue" {
  name     = "${var.project}-batch-job-queue"
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.fargate_environment.arn,
  ]
}

resource "aws_batch_job_definition" "prefilter" {
  name = "${var.project}_prefilter"
  type = "container"
  platform_capabilities = [
    "FARGATE",
  ]

  container_properties = <<CONTAINER_PROPERTIES
{
  "command": ["Rscript", "sctript.R"],
  "image": "${aws_ecr_repository.r_docker.repository_url}",
  "fargatePlatformConfiguration": {
    "platformVersion": "1.4.0"
  },
  "resourceRequirements": [
    {"type": "VCPU", "value": "${var.julia_cpus}"},
    {"type": "MEMORY", "value": "${var.julia_memory}"}
  ],
  "executionRoleArn": "${aws_iam_role.task_execution_role.arn}",
  "volumes": [
    {
      "name": "efs",
      "efsVolumeConfiguration": {
        "fileSystemId": "${aws_efs_file_system.efs-storage.id}",
        "rootDirectory": "/efs"
      }
    }
  ]
}
CONTAINER_PROPERTIES
}

resource "aws_batch_job_definition" "circuitscape" {
  name = "${var.project}_circuitscape"
  type = "container"
  platform_capabilities = [
    "FARGATE",
  ]

  container_properties = <<CONTAINER_PROPERTIES
{
  "command": ["julia", "--project=.", "circuitscape.jl"],
  "image": "${aws_ecr_repository.julia_docker.repository_url}",
  "fargatePlatformConfiguration": {
    "platformVersion": "1.4.0"
  },
  "resourceRequirements": [
    {"type": "VCPU", "value": "${var.julia_cpus}"},
    {"type": "MEMORY", "value": "${var.julia_memory}"}
  ],
  "executionRoleArn": "${aws_iam_role.task_execution_role.arn}",
  "volumes": [
    {
      "name": "efs",
      "efsVolumeConfiguration": {
        "fileSystemId": "${aws_efs_file_system.efs-storage.id}",
        "rootDirectory": "/efs"
      }
    }
  ]
}
CONTAINER_PROPERTIES
}


output "queue" {
  description = "The batch queue"
  value       = aws_batch_job_queue.queue.id
}
