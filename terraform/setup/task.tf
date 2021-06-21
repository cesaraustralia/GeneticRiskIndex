
resource "aws_iam_role" "instance_role" {
  name = "instance_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
            "Service": "ec2.amazonaws.com"
        }
    }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "instance_role" {
  role       = aws_iam_role.instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "instance_role" {
  name = "instance_role"
  role = aws_iam_role.instance_role.name
}

resource "aws_iam_role" "aws_batch_service_role" {
  name = "aws_batch_service_role"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
    {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
        "Service": "batch.amazonaws.com"
        }
    }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "aws_batch_service_role" {
  role       = aws_iam_role.aws_batch_service_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBatchServiceRole"
}

resource "aws_batch_compute_environment" "circuitscape" {
  compute_environment_name = "circuitscape"

  compute_resources {
    max_vcpus = 8
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

resource "aws_iam_role" "task_execution_role" {
  name               = "${var.project}_batch_exec_role"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}


resource "aws_batch_job_definition" "circuitscape" {
  name = "${var.project}_batch_job_definition"
  type = "container"
  platform_capabilities = [
    "FARGATE",
  ]

  container_properties = <<CONTAINER_PROPERTIES
{
  "command": ["julia", "--project=~/GeneticRiskIndex/julia", "~/GeneticRiskIndex/julia/circuitscape.jl", "Ref::taxon_key"],
  "image": "${aws_ami_from_instance.julia-ami.id}",
  "fargatePlatformConfiguration": {
    "platformVersion": "1.4.0"
  },
  "resourceRequirements": [
    {"type": "VCPU", "value": "${var.julia_cpus}"},
    {"type": "MEMORY", "value": "${var.julia_instance_memory}"}
  ],
  "executionRoleArn": "${aws_iam_role.task_execution_role.arn}",
  "volumes": [
    {
      "name": "efs",
      "efsVolumeConfiguration": {
        "fileSystemId": "${aws_efs_file_system.efs-storage.id}"
      }
    }
  ]
}
CONTAINER_PROPERTIES
}

resource "aws_batch_job_queue" "circuitscape_queue" {
  name     = "${var.project}-batch-job-queue"
  state    = "ENABLED"
  priority = 1
  compute_environments = [
    aws_batch_compute_environment.circuitscape.arn,
  ]
}
