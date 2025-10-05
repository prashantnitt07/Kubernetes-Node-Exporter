terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "~> 1.14"
    }
  }
}

provider "kubectl" {
  config_path = "~/.kube/config"
}

#1. Create monitoring namespace
resource "kubectl_manifest" "monitoring_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: monitoring
YAML
}



# Deploy Node Exporter DaemonSet + Service
resource "kubectl_manifest" "node_exporter" {
  yaml_body = file("${path.module}/manifests/node-exporter.yaml")
  depends_on = [kubectl_manifest.monitoring_namespace]
}

# Deploy Node Exporter DaemonSet - Service


resource "kubectl_manifest" "node-exporter-service" {
  yaml_body = file("${path.module}/manifests/node-exporter-service.yaml")
  depends_on = [kubectl_manifest.monitoring_namespace]
}

# (Optional) Use SHA hash to force reapply if manifest changes
locals {
  node_exporter_hash = filesha256("${path.module}/manifests/node-exporter.yaml")
}

resource "null_resource" "trigger_node_exporter_restart" {
  triggers = {
    config_hash = local.node_exporter_hash
  }

  provisioner "local-exec" {
    command = "kubectl rollout restart daemonset/node-exporter -n monitoring || true"
  }
#}
