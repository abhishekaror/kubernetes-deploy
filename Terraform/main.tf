provider "kubernetes" {
  config_path = "~/.kube/config"
}

resource "kubernetes_namespace" "example" {
  metadata {
    name = "default"
  }
}

resource "kubernetes_deployment" "primary" {
  metadata {
    name   = "primary-deployment"
    namespace = kubernetes_namespace.example.metadata.*.name
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
          image = "primary-image:latest"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "canary" {
  metadata {
    name   = "canary-deployment"
    namespace = kubernetes_namespace.example.metadata.*.name
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
          image = "canary-image:latest"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_deployment" "redis" {
  metadata {
    name   = "redis-deployment"
    namespace = kubernetes_namespace.example.metadata.*.name
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
            name      = "redis-storage"
          }
        }
        volume {
          name = "redis-storage"
          persistent_volume_claim {
            claim_name = "redis-pvc"
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "primary" {
  metadata {
    name   = "service-primary"
    namespace = kubernetes_namespace.example.metadata.*.name
  }
  spec {
    selector = {
      app = "primary"
    }
    port {
      port     = 80
      target_port = 80
    }
  }
}

resource "kubernetes_service" "canary" {
  metadata {
    name   = "service-canary"
    namespace = kubernetes_namespace.example.metadata.*.name
  }
  spec {
    selector = {
      app = "canary"
    }
    port {
      port     = 80
      target_port = 80
    }
  }
}

resource "kubernetes_service" "redis" {
  metadata {
    name   = "service-redis"
    namespace = kubernetes_namespace.example.metadata.*.name
  }
  spec {
    selector = {
      app = "redis"
    }
    port {
      port     = 6379
      target_port = 6379
    }
  }
}


