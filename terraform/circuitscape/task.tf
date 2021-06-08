
provider "aws" {
  region = var.aws_region
  shared_credentials_file = var.aws_credentials
}

data "aws_ami" "julia" {
  most_recent = true
  owners = ["self"]
  filter {
    name   = "name"
    values = ["${var.project}-julia-ami"]
  }
}

# Load all taxa that need circuitscape, from csv 
locals {
  taxa = csvdecode(file(var.resistance_taxa_csv))
}

# Define a task for each taxon that will run 
# a separate container, with julia/circuitscape pre-installed
resource "aws_ecs_task_definition" "julia-task" {
  for_each = {for taxon in local.taxa : replace(taxon.delwp_taxon, " ", "_") => taxon}
  family = "julia-task"
  container_definitions = jsonencode([
    {
      # Name the containe
      name      = "${var.project}-julia-${each.key}"
      # Use the julia-ami image made in the setup project
      image     = data.aws_ami.julia.id
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

  placement_constraints {
    type       = "memberOf"
    expression = "attribute:ecs.availability-zone in [${var.aws_region}]"
  }

  # Run Circuitscape.jl model
  provisioner "local-exec" {
    command = "julia --project=~/GeneticRiskIndex/julia ~/GeneticRiskIndex/julia/circuitscape.jl"
  }

}

