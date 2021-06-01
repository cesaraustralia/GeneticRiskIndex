
# Load all taxa that need circuitscape, from csv 
locals {
  taxa = csvdecode(file("taxa.csv"))
}

# Define a task for each taxon that will run 
# a separate server with julia/circuitscape
resource "aws_ecs_task_definition" "julia-task" {
  for_each = {for taxon in local.taxa: taxon.taxon_id => taxon}
  family = "julia-task"
  container_definitions = jsonencode([
    {
      name      = "${var.project}-julia-id-${each.key}"
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

  provisioner "local-exec" {
    command = "link -s /etc/efs-storage/taxon/${each.key} ~/taxon_data"
  }

}
