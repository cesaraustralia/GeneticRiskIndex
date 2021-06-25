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

resource "aws_ecr_repository" "r-docker" {
  name = "${var.project}-r"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_repository" "julia-docker" {
  name = "${var.project}-julia"
  image_tag_mutability = "MUTABLE"
  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "null_resource" "local_docker_build" {
  depends_on = [
    aws_ecr_repository.r-docker,
    aws_ecr_repository.julia-docker,
  ]
  provisioner "local-exec" {
    command = <<EOF
      $(aws ecr get-login --registry-ids 364518226878  --no-include-email)
      cd ../../docker/R
      sudo docker build -t ${var.project}-r .
      sudo docker tag ${var.project}-r:latest ${aws_ecr_repository.julia-docker.repository_url}:latest
      sudo docker push ${aws_ecr_repository.r-docker.repository_url}
      cd ../../docker/julia
      sudo docker build -t ${var.project}-julia .
      sudo docker tag ${var.project}-julia:latest ${aws_ecr_repository.julia-docker.repository_url}:latest
      docker push ${aws_ecr_repository.julia-docker.repository_url}
    EOF
  }
}
