# Plan:
# - create cluster with terraform
# - Create nodes as usual through terraform
# - Execute registration command as last post-provisionning step

resource "rancher2_cluster" "archive-staging" {
  name = "archive-staging"
  description = "Archive staging cluster"
  rke_config {
    kubernetes_version = "v1.23.14-rancher1-1"
    network {
      plugin = "canal"
    }
    ingress {
      default_backend = false
      provider = "none"
    }
    services {
      kubelet {
        extra_args = {
          feature-gates = "NodeSwap=true"
        }
      }
    }
    upgrade_strategy {
      drain = true
      drain_input {
        delete_local_data = true
        timeout = 300
      }
    }
  }
}

output "rancher2_cluster_archive_staging_summary" {
  sensitive = true
  value = rancher2_cluster.archive-staging.kube_config
}

output "rancher2_cluster_archive_staging_command" {
  sensitive = true
  value = rancher2_cluster.archive-staging.cluster_registration_token[0].node_command
}

resource "rancher2_app_v2" "archive-staging-rancher-monitoring" {
  cluster_id = rancher2_cluster.archive-staging.id
  name = "rancher-monitoring"
  namespace = "cattle-monitoring-system"
  repo_name = "rancher-charts"
  chart_name = "rancher-monitoring"
  chart_version = "100.1.3+up19.0.3"
  values = <<EOF
nodeExporter:
  serviceMonitor:
    enabled: true
    relabelings:
    - action: replace
      regex: ^(.*)$
      replacement: $1
      sourceLabels:
      - __meta_kubernetes_pod_node_name
      targetLabel: instance
prometheus:
  enabled: true
  prometheusSpec:
    externalLabels:
      cluster: ${rancher2_cluster.archive-staging.name}
      domain: staging
      environment: staging
      infrastructure: kubernetes
    requests:
      cpu: 250m
      memory: 250Mi
    thanos:
      objectStorageConfig:
        key: thanos.yaml
        name: thanos-objstore-config-secret
  thanosIngress:
    annotations:
      cert-manager.io/cluster-issuer: letsencrypt-production-gandi
      metallb.universe.tf/allow-shared-ip: clusterIP
      nginx.ingress.kubernetes.io/backend-protocol: GRPC
    enabled: true
    hosts:
    - k8s-archive-staging-thanos.internal.staging.swh.network
    loadBalancerIP: 192.168.130.129
    pathType: Prefix
    tls:
    - hosts:
      - k8s-archive-staging-thanos.internal.staging.swh.network
      secretName: thanos-crt
EOF
}
