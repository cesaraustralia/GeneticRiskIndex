
# Default variables
# Override in your main.tfvars file in this directory

variable "project" {
  type = string
  default = "unnamed"
}

variable "julia_cpus" {
  type = number
  default = 2
}

variable "julia_instance_memory" {
  type = number
  default = 2048
}

variable "aws_region" {
  type = string
  default = "ap-southeast-2"
}

variable "aws_credentials" {
  type = string
}

variable "resistance_taxa_csv" {
  type = string
  default = "../../data/resistance_taxa.csv"
}
