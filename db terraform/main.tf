provider "google" {
  project = "dkkom-446515"
  region  = "europe-west4"
}

resource "google_compute_instance" "scylla-node1" {
  boot_disk {
    auto_delete = true
    device_name = "scylla-node1"

    initialize_params {
      image = "projects/cos-cloud/global/images/cos-stable-117-18613-75-102"
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
    network_ip  = "10.164.0.2"
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
}

resource "google_compute_instance" "scylla-node2" {
  boot_disk {
    auto_delete = true
    device_name = "scylla-node2"

    initialize_params {
      image = "projects/cos-cloud/global/images/cos-stable-117-18613-75-102"
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
}
