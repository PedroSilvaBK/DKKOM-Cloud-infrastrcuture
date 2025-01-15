provider "google" {
  project = "dkkom-446515"
  region  = "europe-west4"
}

resource "google_compute_router" "cluster_router" {
  name    = "cluster-router"
  network = "default"
  region  = "europe-west4"
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

resource "google_compute_instance" "scylla-node1" {
  boot_disk {
    auto_delete = true
    device_name = "scylla-node1"

    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-11"
      size  = 20
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = "e2-standard-2"
  name         = "scylla-node1"

  network_interface {
    network_ip  = "10.164.0.7"
    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/dkkom-446515/regions/europe-west4/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    mkdir -p /etc/apt/keyrings
    gpg --homedir /tmp --no-default-keyring --keyring /etc/apt/keyrings/scylladb.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys a43e06657bac99e3
    wget -O /etc/apt/sources.list.d/scylla.list https://downloads.scylladb.com/deb/debian/scylla-6.2.list
    apt-get update
    apt-get install -y scylla
  EOT


  service_account {
    email  = "default"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = ["scylla-node1"]
  zone = "europe-west4-b"

  depends_on = [ google_compute_router.cluster_router, google_compute_router_nat.cluster_nat ]
}

resource "google_compute_instance" "scylla-node2" {
  boot_disk {
    auto_delete = true
    device_name = "scylla-node2"

    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-11"
      size  = 20
      type  = "pd-balanced"
    }

    mode = "READ_WRITE"
  }

  can_ip_forward      = false
  deletion_protection = false
  enable_display      = false

  labels = {
    goog-ec-src = "vm_add-tf"
  }

  machine_type = "e2-standard-2"
  name         = "scylla-node2"

  network_interface {
    network_ip  = "10.164.0.3"
    queue_count = 0
    stack_type  = "IPV4_ONLY"
    subnetwork  = "projects/dkkom-446515/regions/europe-west4/subnetworks/default"
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
    provisioning_model  = "STANDARD"
  }


  metadata_startup_script = <<-EOT
    #!/bin/bash
    mkdir -p /etc/apt/keyrings
    gpg --homedir /tmp --no-default-keyring --keyring /etc/apt/keyrings/scylladb.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys a43e06657bac99e3
    wget -O /etc/apt/sources.list.d/scylla.list https://downloads.scylladb.com/deb/debian/scylla-6.2.list
    apt-get update
    apt-get install -y scylla
  EOT


  service_account {
    email  = "default"
    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }
  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = false
    enable_vtpm                 = true
  }

  tags = ["scylla-node2"]
  zone = "europe-west4-b"

  depends_on = [ google_compute_router.cluster_router, google_compute_router_nat.cluster_nat ]
}
