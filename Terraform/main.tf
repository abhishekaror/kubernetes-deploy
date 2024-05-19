provider "kubernetes" {
 config_context = "gke_pradeep-poc_us-central1_autopilot-cluster-1"
}

resource "kubernetes_deployment" "canary" {
  metadata {
    name      = "canary-deployment"
    namespace = "default"
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "canary"
      }
    }

    template {
      metadata {
        labels = {
          app = "canary"
        }
      }

      spec {
        container {
          name  = "canary-container"
          image = "argoproj/rollouts-demo:blue"

          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "primary" {
  metadata {
    name      = "primary-deployment"
    namespace = "default"
  }

  spec {
    replicas = 3

    selector {
      match_labels = {
        app = "primary"
      }
    }

    template {
      metadata {
        labels = {
          app = "primary"
        }
      }

      spec {
        container {
          name  = "primary-container"
          image = "argoproj/rollouts-demo:green"

          port {
            container_port = 8080
          }
        }
      }
    }
  }
}

resource "kubernetes_ingress" "nginx" {
  metadata {
    name      = "ingress-primary-canary"
    namespace = "default"
  }

  spec {
    rule {
      host = "example.com"

      http {
        path {
          path     = "/"

          backend {
            service_name = kubernetes_service.primary.metadata.0.name
            service_port = kubernetes_service.primary.spec.0.port.0.target_port
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "redis" {
  metadata {
    name      = "redis-deployment"
    namespace = "default"
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "redis"
      }
    }

    template {
      metadata {
        labels = {
          app = "redis"
        }
      }

      spec {
        container {
          name  = "redis-container"
          image = "redis:latest"

          port {
            container_port = 6379
          }

          volume_mount {
            mount_path = "/data"
            name       = "redis-storage"
          }
        }

        volume {
          name = "redis-storage"

          persistent_volume_claim {
            claim_name = kubernetes_persistent_volume_claim.redis_pvc.metadata.0.name
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "primary" {
  metadata {
    name      = "service-primary"
    namespace = "default"
  }

  spec {
    selector = {
      app = "primary"
    }

    port {
      name       = "http"
      protocol   = "TCP"
      port       = 80
      target_port = 80
    }

    port {
      name       = "custom-port"
      protocol   = "TCP"
      port       = 30899
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

resource "kubernetes_service" "canary" {
  metadata {
    name      = "service-canary"
    namespace = "default"
  }

  spec {
    selector = {
      app = "canary"
    }

    port {
      protocol   = "TCP"
      port       = 80
      target_port = 8080
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name      = "service-redis"
    namespace = "default"
  }

  spec {
    selector = {
      app = "redis"
    }

    port {
      protocol   = "TCP"
      port       = 6379
      target_port = 6379
    }
  }
}

resource "kubernetes_persistent_volume" "redis_pv" {
  metadata {
    name = "redis-pv"
  }

  spec {
    capacity = { storage = "10Gi" }
    access_modes = ["ReadWriteOnce"]  # Moved inside the spec block

    persistent_volume_source {
      gce_persistent_disk {
        pd_name = "redis-disk"
        fs_type = "ext4"
      }
    }
  }
}

resource "kubernetes_persistent_volume_claim" "redis_pvc" {
  metadata {
    name = "redis-pvc"
  }

  spec {
    access_modes = ["ReadWriteOnce"]
    resources {
      requests = {
        storage = "1Gi"
      }
    }
  }
}



