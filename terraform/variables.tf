
# Default variables
# Override in your main.tfvars file in this directory

variable "project" {
  type = string
}

variable "project_repo" {
  type = string
}

variable "s3_bucket" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "aws_availability_zone" {
  type = string
}

variable "aws_credentials" {
  type = string
  default = "~/.aws/credentials"
}

variable "private_key" {
  type = string
  default = "key.pem"
}

variable "public_key" {
  type = string
  default = "key.pem.pub"
}

variable "public_key_openssh" {
  type = string
  default = "key.openssh.pub"
}

variable "r_cpus" {
  type = number
  default = 2
}

variable "r_memory" {
  type = number
  default = 16384
}

variable "julia_cpus" {
  type = number
  default = 1
}

variable "julia_memory" {
  type = number
  default = 8192
}

variable "additional_cidrs" {
  type = list
  description = "A list of cidrs to limit security groups"
  default = []     
}

variable "datasync_location_s3_subdirectory" {
  type = string
  description = "The s3 subdirectory job data is synced to with datasync"
  default = "data"
}

variable "datasync_task_options" {
  type        = map
  description = "A map of datasync_task options block"
  default = {
    verify_mode            = "POINT_IN_TIME_CONSISTENT"
    posix_permissions      = "NONE"
    preserve_deleted_files = "REMOVE"
    uid                    = "NONE"
    gid                    = "NONE"
    atime                  = "NONE"
    mtime                  = "NONE"
    bytes_per_second       = "-1"
  }
}
