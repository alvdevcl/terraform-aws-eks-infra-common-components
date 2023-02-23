resource "helm_release" "aws_load_balancer_controller" {

  count = var.aws_load_balancer_controller_enable ? 1 : 0

  name       = "aws-load-balancer-controller"
  repository = "https://cgrepo.capgroup.com/repository/cghelm/"
  chart      = "aws-load-balancer-controller"
  version    = "1.4.1"
  namespace  = "kube-system"
  timeout    = 600

  set {
    name  = "clusterName"
    value = var.eks_cluster_name
  }

  set {
    name  = "serviceAccount.create"
    value = "false"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "enableWaf"
    value = "false"
  }

  set {
    name  = "enableWafv2"
    value = "false"
  }

  // These two vars below are required for EKS Fargate
  set {
    name  = "region"
    value = data.aws_region.current.name
  }

  set {
    name  = "vpcId"
    value = var.vpc_id
  }

}

resource "kubernetes_service_account" "aws_load_balancer_controller" {

  count = var.aws_load_balancer_controller_enable ? 1 : 0

  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.aws_lb_controller_role[0].arn
    }

    labels = {
      "app.kubernetes.io/component" = "controller"
      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
    }
  }

}


## AWS Load Balancer Controller
resource "aws_iam_policy" "aws_lb_controller_policy" {

  count = var.aws_load_balancer_controller_enable ? 1 : 0

  name        = "${var.eks_cluster_name}-LoadBalancerControllerPolicy"
  description = "IAM Policy for EKS Load Balancer Controller"

  policy = file("${path.module}/files/aws_lb_controller_policy.json")

  tags = var.tags

}

resource "aws_iam_role" "aws_lb_controller_role" {

  count = var.aws_load_balancer_controller_enable ? 1 : 0

  name                 = "${var.eks_cluster_name}-EKSLoadBalancerControllerRole"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${local.aws_account_id}:oidc-provider/${local.oidc_output}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${local.oidc_output}:sub" : "system:serviceaccount:kube-system:aws-load-balancer-controller"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, { "compliance-app" = "cross-account" })

}

resource "aws_iam_role_policy_attachment" "attach_aws_lb_policy" {

  count = var.aws_load_balancer_controller_enable ? 1 : 0

  role       = aws_iam_role.aws_lb_controller_role[0].name
  policy_arn = aws_iam_policy.aws_lb_controller_policy[0].arn
}


resource "helm_release" "autosys_k8s_pojo" {

  count = var.autosys_enable ? 1 : 0

  name       = "autosys-k8s-pojo"
  repository = "https://cgrepo.capgroup.com/repository/cghelm/"
  chart      = "autosys-k8s-pojo"
  version    = "0.3.0"
  timeout    = 600

}

#VeleroBackup
#Velero S3
#Velero S3 bucket
resource "aws_s3_bucket" "velero_s3_bucket" {
  count         = var.velero_backup_enable ? 1 : 0
  bucket_prefix = "${var.velero_backup_bucket}-"
  tags          = merge(var.tags, { "backup" = "not-required-temporary-s3" })
}

#Velero Bucket logging
resource "aws_s3_bucket_logging" "velero_s3_bucket_logging" {
  count  = var.velero_backup_enable ? 1 : 0
  bucket = aws_s3_bucket.velero_s3_bucket[0].id

  target_bucket = local.velero_s3_log_bucket
  target_prefix = ""
}

#Velero Bucket SSE
resource "aws_s3_bucket_server_side_encryption_configuration" "velero_s3_bucket_sse" {
  count  = var.velero_backup_enable ? 1 : 0
  bucket = aws_s3_bucket.velero_s3_bucket[0].bucket
  rule {
    apply_server_side_encryption_by_default {
      kms_master_key_id = var.velero_s3_kms_key_arn
      sse_algorithm     = "aws:kms"
    }
  }
}

#Velero Bucket ACL
resource "aws_s3_bucket_acl" "velero_s3_bucket_acl" {
  count  = var.velero_backup_enable ? 1 : 0
  bucket = aws_s3_bucket.velero_s3_bucket[0].id
  acl    = "private"
}

#Velero Backup Policy
resource "aws_iam_policy" "velero_backup_policy" {
  count       = var.velero_backup_enable ? 1 : 0
  name_prefix = "VeleroEKSAccessPolicy-"
  description = "IAM Policy for Velero Backups"
  policy      = file("${path.module}/files/velero_backup_policy.json")

  tags = var.tags

}

#Velero Role
resource "aws_iam_role" "velero_backup_role" {
  count                = var.velero_backup_enable ? 1 : 0
  name_prefix          = "VeleroEKSBackupRole-"
  permissions_boundary = var.permissions_boundary

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "Federated" : "arn:aws:iam::${local.aws_account_id}:oidc-provider/${local.oidc_output}"
        },
        "Action" : "sts:AssumeRoleWithWebIdentity",
        "Condition" : {
          "StringEquals" : {
            "${local.oidc_output}:sub" : "system:serviceaccount:velero:velero-server"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, { "compliance-app" = "cross-account" })
}

#Velero Policy Attach 
resource "aws_iam_role_policy_attachment" "attach_velero_backup_policy" {
  count      = var.velero_backup_enable ? 1 : 0
  role       = aws_iam_role.velero_backup_role[0].name
  policy_arn = aws_iam_policy.velero_backup_policy[0].arn
}

#Deploy Velero to the cluster
resource "helm_release" "velero_backup" {
  count            = var.velero_backup_enable ? 1 : 0
  name             = "velero"
  repository       = "https://cgrepo.capgroup.com/repository/cghelm/"
  chart            = "velero"
  namespace        = "velero"
  create_namespace = true
  version          = "2.29.4"
  timeout          = 600

  #Overwrite image pull to proxy from nexus registry(cgregistry)
  values = [
    file("${path.module}/files/velero-helm-values.yaml")
  ]

  set {
    name  = "configuration.backupStorageLocation.bucket"
    value = aws_s3_bucket.velero_s3_bucket[0].id
  }

  set {
    name  = "serviceAccount.server.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.velero_backup_role[0].arn
  }

  set {
    name  = "schedules.scheduledbackup.schedule"
    value = var.velero_schedule
  }

}

#CoreDNS add-on install
resource "aws_eks_addon" "core_dns" {
  cluster_name      = var.eks_cluster_name
  addon_name        = "coredns"
  resolve_conflicts = var.coredns_resolve_conflicts
  addon_version     = var.coredns_addon_version

}

#kube-proxy add-on install
resource "aws_eks_addon" "kube_proxy" {
  cluster_name      = var.eks_cluster_name
  addon_name        = "kube-proxy"
  resolve_conflicts = var.kube_proxy_resolve_conflicts
  addon_version     = var.kube_proxy_addon_version

}

#External Secrets Operator
resource "helm_release" "external_secrets_operator" {

  count            = var.external_secrets_operator_enable ? 1 : 0
  repository       = "https://cgrepo.capgroup.com/repository/cghelm/"
  name             = "external-secrets"
  chart            = "external-secrets"
  version          = "0.5.9"
  namespace        = "external-secrets"
  create_namespace = "true"
  timeout          = 600

  values = [
    file("${path.module}/templates/external-secrets-operator-helm-values.yaml")
  ]

}


data "aws_eks_cluster" "control_plane" {
  name = var.eks_cluster_name
}

data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  oidc_output          = trimprefix(data.aws_eks_cluster.control_plane.identity[0].oidc[0].issuer, "https://")
  aws_account_id       = data.aws_caller_identity.current.account_id
  velero_s3_log_bucket = "${local.aws_account_id}-s3-access-logs-${element(split("", "${data.aws_region.current.name}"), 3)}${element(split("", "${data.aws_region.current.name}"), length("${data.aws_region.current.name}") - 1)}"
}
