# Repositories for docker images #########################################

resource "aws_ecr_repository" "r_docker" {
  name = "${var.project}-r"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_repository" "julia_docker" {
  name = "${var.project}-julia"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
}

# Null resources that just run the docker task locally ###################
# It may be preferable to run these in the cloud at some point.

resource "null_resource" "local_r_docker_build" {
  depends_on = [aws_ecr_repository.r_docker]
  provisioner "local-exec" {
    command = <<EOF
      cd ../docker/R
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.r_docker.repository_url}
      docker build -t ${var.project}-r .
      docker tag ${var.project}-r:latest ${aws_ecr_repository.r_docker.repository_url}:latest
      docker push ${aws_ecr_repository.r_docker.repository_url}
    EOF
  }
}

resource "null_resource" "local_julia_docker_build" {
  depends_on = [aws_ecr_repository.julia_docker]
  provisioner "local-exec" {
    command = <<EOF
      cd ../docker/julia
      aws ecr get-login-password --region ${var.aws_region} | docker login --username AWS --password-stdin ${aws_ecr_repository.julia_docker.repository_url}
      docker build -t ${var.project}-julia .
      docker tag ${var.project}-julia:latest ${aws_ecr_repository.julia_docker.repository_url}:latest
      docker push ${aws_ecr_repository.julia_docker.repository_url}
    EOF
  }
}
