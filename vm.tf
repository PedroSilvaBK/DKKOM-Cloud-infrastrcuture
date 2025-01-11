provider "google" {
  project = "dkkom-446515"
  region  = "europe-west1"
}


resource "google_compute_instance" "example_instance" {
  name         = "instance-20250107-132118"
  machine_type = "e2-medium"

  tags = ["turn-server"]

  boot_disk {
    auto_delete = true
    device_name = "instance-20250107-132118"

    initialize_params {
      image = "projects/debian-cloud/global/images/family/debian-12"
      size  = 10
      type  = "pd-standard"
    }
  }

  network_interface {
    network    = "default"
    subnetwork = "projects/dkkom-446515/regions/europe-west1/subnetworks/default"

    access_config {
      nat_ip = "35.210.177.27"
    }
  }

  service_account {
    email  = "953454344870-compute@developer.gserviceaccount.com"
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_only",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
      "https://www.googleapis.com/auth/service.management.readonly",
      "https://www.googleapis.com/auth/servicecontrol",
      "https://www.googleapis.com/auth/trace.append",
    ]
  }

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
    preemptible         = false
  }

  shielded_instance_config {
    enable_secure_boot          = false
    enable_vtpm                 = true
    enable_integrity_monitoring = true
  }

  confidential_instance_config {
    enable_confidential_compute = false
  }
}
