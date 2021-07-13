# resource "aws_cloudwatch_log_group" "dockerbuild" {
#   name = "dockerbuild_${var.project}"
#   tags = {
#     Name = "dockerbuild_${var.project}"
#   }
# }

# resource "aws_iam_role" "dockerbuild_role" {
#   name = "${var.project}_dockerbuild_role"
#   assume_role_policy = "${data.aws_iam_policy_document.dockerbuild_assume_role_policy.json}"
#   tags = {
#     Name = "${var.project}_dockerbuild_role"
#     Created_by = "terraform"
#   }
# }

# resource "aws_iam_role_policy" "dockerbuild_role_policy" {
#   name = "${var.project}_docker_build_role_policy"
#   role = "${aws_iam_role.dockerbuild_role.name}"
#   policy = "${data.aws_iam_policy_document.dockerbuild_policy.json}"
# }

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
