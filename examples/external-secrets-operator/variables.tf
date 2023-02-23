variable "tags" {
  type = map(any)
}

variable "aws_region" {
  type = string
}

variable "eks_cluster_name" {
  type    = string
  default = "pds-blueprint-control-plane"
}

variable "permissions_boundary" {
  type        = string
  default     = null
  description = "The IAM policy to assign as a permissions boundary on roles created by the pipeline."
}
