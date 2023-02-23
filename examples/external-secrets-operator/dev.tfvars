#EKS Control Plane Name 
eks_cluster_name = "pds-blueprint-control-plane"

# Permissions boundary to attach to all roles created by the pipeline
permissions_boundary = "arn:aws:iam::836816519470:policy/AdminPermissionsBoundary"

#AWS Region your cluster is deployed in 
aws_region = "us-west-2"

#Mandatory Tags
tags = {
  "cost-center" = "524068"
  "env-type"    = "DEV"
  "exp-date"    = "99-00-9999"
  "ppmc-id"     = "80502"
  "toc"         = "ETOC"
  "sd-period"   = "NA"
  "usage-id"    = "BB00000085"
}
