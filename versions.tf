#Pinning the provider versions
terraform {
  required_version = ">= 0.13.3"
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.4.1"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.8.0"
    }
    aws = {
      source  = "hashicorp/aws"
      version = ">= 3.73.0"
    }
  }
}
