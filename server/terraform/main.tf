# Compute instance: 2 vCPU / 4 GB (e2-medium)
resource "google_compute_instance" "vm" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = var.image
      size  = var.disk_size_gb
    }
  }

  network_interface {
    network = var.network

    # Ephemeral external IP so the VM is reachable and can be DNS-mapped.
    access_config {}
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(pathexpand(var.ssh_public_key_path))}"
  }

  tags = ["http-server", "https-server", "ssh"]

  labels = {
    app = "book-app"
    env = "test"
  }
}

# Allow inbound SSH / HTTP / HTTPS to the VM.
resource "google_compute_firewall" "allow_ingress" {
  name    = "${var.instance_name}-allow-ingress"
  network = var.network

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443", "6443"] # 6443 = K3s API
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["ssh", "http-server", "https-server"]
}

# Cloud DNS managed zone
resource "google_dns_managed_zone" "zone" {
  name        = var.dns_zone_name
  dns_name    = var.dns_domain
  description = "Managed zone for the book-app"
}

# A record pointing the chosen hostname at the VM's external IP.
resource "google_dns_record_set" "a_record" {
  name         = "${var.dns_record_name}.${google_dns_managed_zone.zone.dns_name}"
  managed_zone = google_dns_managed_zone.zone.name
  type         = "A"
  ttl          = var.dns_ttl

  rrdatas = [
    google_compute_instance.vm.network_interface[0].access_config[0].nat_ip,
  ]
}
