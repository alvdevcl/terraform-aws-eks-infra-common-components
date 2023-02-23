resource "aws_iam_policy" "phlp_secrets_policy" {

  name        = "${var.eks_cluster_name}-phlp-policy"
  description = "IAM Policy for PHLP service1"

  policy = file("${path.module}/phlp_secrets_policy.json")

  tags = var.tags

}

resource "aws_iam_role" "phlp_service1_role" {

  name                 = "${var.eks_cluster_name}-phlp-service1-role"
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
            "${local.oidc_output}:sub" : "system:serviceaccount:default:phlp-secrets-role",
            "${local.oidc_output}:aud" : "sts.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = merge(var.tags, { "compliance-app" = "cross-account" })

}

resource "aws_iam_role_policy_attachment" "attach_cluster_autoscaler_policy" {

  role       = aws_iam_role.phlp_service1_role.name
  policy_arn = aws_iam_policy.phlp_secrets_policy.arn

}

resource "kubernetes_service_account" "phlp_service1" {

  metadata {
    name      = "phlp-secrets-role"
    namespace = "default"

    annotations = {
      "eks.amazonaws.com/role-arn" = aws_iam_role.phlp_service1_role.arn
    }

  }

}


data "aws_caller_identity" "current" {}

data "aws_region" "current" {}

locals {
  oidc_output    = trimprefix(data.aws_eks_cluster.default.identity[0].oidc[0].issuer, "https://")
  aws_account_id = data.aws_caller_identity.current.account_id
}
