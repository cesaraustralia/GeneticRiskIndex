
provider "aws" {
  region = var.aws_region
  shared_credentials_file = var.aws_credentials
}

# Load all taxa that need circuitscape, from csv 
locals {
  taxa = csvdecode(file(var.resistance_taxa_csv))
}

# Define a task for each taxon that will run 
# a separate server with julia/circuitscape
resource "aws_ecs_task_definition" "julia-task" {
  for_each = {for taxon in local.taxa: taxon.taxon_id => taxon}
  family = "julia-task"
  container_definitions = jsonencode([
    {
      # Name the containe
      name      = "${var.project}-julia-id-${each.key}"
      # Use the julia-ami image made in the setup project
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

  # Add a shared volume to access pre-calculated data
  volume {
    name      = "efs-storage"
    host_path = "/ecs/efs-storage"
  }

  # Run in our region for fast data transfer
  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${var.aws_region}]"
  }

  # Make a link to the folder of the taxon we are modelling in this task
  provisioner "local-exec" {
    command = "link -s /etc/efs-storage/taxon/${each.key} ~/taxon_data"
  }

}
