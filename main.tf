terraform {
  backend "gcs" {
    bucket  = "dkkcom-image-bucket"         # Replace with your GCS bucket name
    prefix  = "terraform/state"             # Path in the bucket to store the state file
  }
}

provider "google" {
  project = "d-com-437216"
  region  = "europe-west1"
}

resource "google_redis_instance" "redis_instance" {
  name            = "redis"
  tier            = "BASIC"         # Equivalent to --tier=basic
  memory_size_gb  = 8               # --size=8
  region          = "europe-west1"
  redis_version   = "REDIS_7_0"     # Equivalent to --redis-version=redis_7_0

  connect_mode    = "PRIVATE_SERVICE_ACCESS"  # Equivalent to --connect-mode=PRIVATE_SERVICE_ACCESS

  authorized_network = "projects/d-com-437216/global/networks/default" # Network configuration
}

resource "google_compute_router" "cluster_router" {
  name    = "cluster-router"
  network = "default"
  region  = "europe-west1"
}

resource "google_compute_router_nat" "cluster_nat" {
  name   = "cluster-nat"
  router = google_compute_router.cluster_router.name
  region = google_compute_router.cluster_router.region

  nat_ip_allocate_option    = "AUTO_ONLY"  # Equivalent to --auto-allocate-nat-external-ips
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"  # Equivalent to --nat-all-subnet-ip-ranges

  min_ports_per_vm = 64
  log_config {
    enable = false
    filter = "ERRORS_ONLY"
  }
}

resource "google_container_cluster" "dcom_cluster" {
  name                   = "dcom-cluster"
  location               = "europe-west1-b"
  network                = "projects/d-com-437216/global/networks/default"
  subnetwork             = "projects/d-com-437216/regions/europe-west1/subnetworks/default"

  remove_default_node_pool = true
  initial_node_count       = 1

  # Release channel configuration
  release_channel {
    channel = "RAPID"
  }

  # IP alias and private nodes
  private_cluster_config {
    enable_private_nodes = true
  }

  # Addons configuration
  addons_config {
    horizontal_pod_autoscaling {
      disabled = false
    }
    http_load_balancing {
      disabled = false
    }
  }

  # Default pods per node
  default_max_pods_per_node = 30

  # Security posture and features
  security_posture_config {
    mode = "BASIC"
  }
  enable_shielded_nodes = true

  # Monitoring and logging
  monitoring_config {
    managed_prometheus {
      enabled = true
    }
  }

  deletion_protection = false

  workload_identity_config {
    workload_pool = "d-com-437216.svc.id.goog"
  }

  secret_manager_config {
    enabled = true
  }
}

# Define a separate node pool
resource "google_container_node_pool" "default_node_pool" {
  cluster    = google_container_cluster.dcom_cluster.name
  location   = google_container_cluster.dcom_cluster.location
  node_count = 3

  node_config {
    machine_type = "e2-medium"
    disk_type    = "pd-balanced"
    disk_size_gb = 20
    image_type   = "COS_CONTAINERD"
    metadata = {
      disable-legacy-endpoints = "true"
    }
    oauth_scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 0
  }
}

resource "google_sql_database_instance" "default" {
  name             = "cave-service-sql"
  database_version = "MYSQL_8_0"
  region           = "europe-west1"

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

  settings {
    tier       = "db-custom-4-16384" # 4 vCPUs, 16 GB RAM
    disk_size  = 20                 # 20 GB
    disk_type  = "PD_SSD"           # SSD Storage
    availability_type = "ZONAL"     # Single Zone

    ip_configuration {
      private_network = "projects/d-com-437216/global/networks/default" # Private VPC Network
      ipv4_enabled    = false
    }

    backup_configuration {
      enabled = false # Automated backups disabled
    }
  }

  deletion_protection = false # Enable deletion protection

}

resource "google_sql_database" "additional_databases" {
  for_each = toset(["cave_db", "users_db"]) # Replace with your database names
  name     = each.value
  instance = google_sql_database_instance.default.name
  charset  = "utf8"
  collation = "utf8_general_ci"

  depends_on = [ google_sql_database_instance.default ]
}

resource "google_sql_user" "root" {
  instance   = google_sql_database_instance.default.name
  name       = "root"
  password   = "admin" # Replace with your actual password
  host       = "%"

  depends_on = [ google_sql_database_instance.default ]
}

output "sql_instance_connection_name" {
  value = google_sql_database_instance.default.connection_name
}


output "sql_instance_ip" {
  value = google_sql_database_instance.default.ip_address[0].ip_address
  description = "Private IP of the SQL instance"
}

output "redis_ip" {
  value = google_redis_instance.redis_instance.host
  description = "Private IP of the Redis instance"
}