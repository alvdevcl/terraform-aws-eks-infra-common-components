variable "aws_load_balancer_controller_enable" {
  type        = bool
  default     = false
  description = "Enable flag to deploy AWS Load Balancer Controller to EKS cluster"
}

variable "eks_cluster_name" {
  type        = string
  description = "Name of your EKS Control Plane"
}

variable "vpc_id" {
  type        = string
  description = "AWS vpc id"
}


#AWS Load Balancer Controller
variable "permissions_boundary" {
  type        = string
  default     = null
  description = "aws arn of permissions boundary to attach to AWS Load Balancer Controller IAM Role"
}

#Autosys Pojo Integration
variable "autosys_enable" {
  type        = bool
  default     = false
  description = "Enable flag to deploy Autosys Pojo Integration"

}

variable "tags" {
  description = "AWS tags which should be applied to all resources that Terraform creates"
  type        = map(string)
  default     = null
}

#CoreDNS EKS Add-On
variable "coredns_resolve_conflicts" {
  type        = string
  default     = "NONE"
  description = "NONE or OVERWRITE which will allow the add-on to overwrite your custom settings"
}

variable "coredns_addon_version" {
  type        = string
  description = "CoreDNS version, please ensure the version is compatible with your k8s version"
}

#kube-proxy EKS Add-On
variable "kube_proxy_resolve_conflicts" {
  type        = string
  default     = "NONE"
  description = "NONE or OVERWRITE which will allow the add-on to overwrite your custom settings"
}

variable "kube_proxy_addon_version" {
  type        = string
  description = "kube-proxy version, please ensure the version is compatible with your k8s version"
}

#Velero Backup
variable "velero_backup_enable" {
  type        = bool
  default     = false
  description = "Deploy Velero objects to the clusters"
}

variable "velero_backup_bucket" {
  type        = string
  default     = "eks-velero-bucket"
  description = "Bucket name for velero to take backups"
}

variable "velero_s3_kms_key_arn" {
  type        = string
  description = "KMS volume key arn which is used for server side encryption of velero bucket"
}

variable "velero_schedule" {
  type        = string
  default     = "0 0 * * *"
  description = "schedule for velero backups"
}

#External Secrets Operator 
variable "external_secrets_operator_enable" {
  type        = string
  default     = "false"
  description = "Deploy External Secrets Operator for secret sync from aws secrets manager"
}
