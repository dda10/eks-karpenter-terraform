# Prometheus and Grafana Stack
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "65.0.0"

  values = [
    yamlencode({
      prometheus = {
        prometheusSpec = {
          retention = "30d"
          storageSpec = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "50Gi"
                  }
                }
              }
            }
          }
          nodeSelector = {
            "karpenter.sh/controller" = "true"
          }
          tolerations = [{
            key    = "karpenter.sh/controller"
            value  = "true"
            effect = "NoSchedule"
          }]
        }
      }
      grafana = {
        adminPassword = "admin"
        persistence = {
          enabled          = true
          storageClassName = "gp3"
          size             = "10Gi"
        }
        service = {
          type = "LoadBalancer"
        }
        nodeSelector = {
          "karpenter.sh/controller" = "true"
        }
        tolerations = [{
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NoSchedule"
        }]
      }
      alertmanager = {
        alertmanagerSpec = {
          storage = {
            volumeClaimTemplate = {
              spec = {
                storageClassName = "gp3"
                accessModes      = ["ReadWriteOnce"]
                resources = {
                  requests = {
                    storage = "10Gi"
                  }
                }
              }
            }
          }
          nodeSelector = {
            "karpenter.sh/controller" = "true"
          }
          tolerations = [{
            key    = "karpenter.sh/controller"
            value  = "true"
            effect = "NoSchedule"
          }]
        }
      }
      prometheusOperator = {
        nodeSelector = {
          "karpenter.sh/controller" = "true"
        }
        tolerations = [{
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NoSchedule"
        }]
      }
      kube-state-metrics = {
        nodeSelector = {
          "karpenter.sh/controller" = "true"
        }
        tolerations = [{
          key    = "karpenter.sh/controller"
          value  = "true"
          effect = "NoSchedule"
        }]
      }
    })
  ]

  depends_on = [module.eks]
}


# NVIDIA DCGM Exporter for GPU Metrics
resource "helm_release" "dcgm_exporter" {
  name             = "dcgm-exporter"
  repository       = "https://nvidia.github.io/dcgm-exporter/helm-charts"
  chart            = "dcgm-exporter"
  namespace        = "monitoring"
  create_namespace = false
  version          = "3.4.2"

  values = [
    yamlencode({
      serviceMonitor = {
        enabled = true
      }
      nodeSelector = {
        "nvidia.com/gpu" = "true"
      }
    })
  ]

  depends_on = [helm_release.kube_prometheus_stack]
}
