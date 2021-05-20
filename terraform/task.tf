resource "aws_ecs_task_definition" "julia-task" {
  family = "julia-task"
  container_definitions = jsonencode([
    {
      name      = "julia"
      image     = "julia-ami"
      cpu       = var.julia_cpus
      memory    = var.julia_instance_memory
      requires_compatibilities = "FARGATE"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])

  volume {
    name      = "efs-storage"
    host_path = "/ecs/efs-storage"
  }

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${var.aws_region}]"
  }
}
