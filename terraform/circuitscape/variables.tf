
# Default variables
# Override in your main.tfvars file in this directory

variable "project" {
  type = string
  default = "genetic-risk-index"
}

variable "julia_cpus" {
  type = number
  default = 4
}

variable "julia_instance_memory" {
  type = number
  default = 8192
}

variable "aws_region" {
  type = string
  default = "ap-southeast-2"
}

variable "aws_credentials" {
  type = string
}

variable "circuitscape_taxa_csv" {
  type = string
  default = "circuitscape_taxa.csv"
}
