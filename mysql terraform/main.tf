provider "google" {
  project = "dkkom-446515"
  region  = "europe-west1"
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
      private_network = "projects/dkkom-446515/global/networks/default" # Private VPC Network
      ipv4_enabled    = false
    }

    backup_configuration {
      enabled = true # Automated backups disabled
      binary_log_enabled = true
    }

    
  }

  deletion_protection = false # Enable deletion protection

}

resource "google_sql_database_instance" "read_replica" {
  name             = "cave-service-sql-replica"
  master_instance_name = google_sql_database_instance.default.name
  database_version = "MYSQL_8_0"
  region           = "europe-west1"

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }

    replica_configuration {
    failover_target = false
  }

  settings {
    tier       = "db-custom-4-16384" # Match primary instance size
    disk_size  = 20                 # Match primary instance disk size
    disk_type  = "PD_SSD"           # Match primary instance storage type
    availability_type = "ZONAL"     # Match primary instance availability

    ip_configuration {
      private_network = "projects/dkkom-446515/global/networks/default" # Same private VPC network
      ipv4_enabled    = false
    }
  }

  deletion_protection = false # Enable or disable deletion protection
}
