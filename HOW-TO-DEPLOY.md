# Runbook: How to Deploy Book App

Panduan ini berisi langkah-langkah komprehensif untuk melakukan deployment aplikasi Book App beserta sistem monitoringnya. Terdapat dua jalur deployment yang didukung:

1. **Docker Compose**: Cocok untuk pengembangan lokal dan environment testing sederhana.
2. **Kubernetes (Production Ready)**: Menggunakan Terraform untuk provisioning VM, Ansible untuk konfigurasi server, dan manifest Kubernetes untuk aplikasinya.

---

## Prasyarat

Sebelum memulai, pastikan sistem Anda sudah terinstal tools berikut sesuai dengan jalur deployment yang Anda pilih:

- Docker & Docker Compose
- Terraform (Untuk jalur Kubernetes)
- Ansible (Untuk jalur Kubernetes)
- `kubectl` (Untuk jalur Kubernetes)
- Git

---

## JALUR A: Deployment menggunakan Docker Compose (Lokal/Development)

### 1. Deploy Backend (dan Blackbox Exporter)

Tahap pertama adalah menjalankan layanan utama (Backend API) beserta _sidecar_ pengeceknya yaitu Blackbox Exporter.

1. Buka terminal dan masuk ke direktori `backend/`:
   ```bash
   cd backend
   ```
2. Salin environment dari contoh:
   ```bash
   cp env.example .env
   ```
3. Jalankan _container_ di background (mode detached):
   ```bash
   docker-compose up -d
   ```
4. Verifikasi bahwa _container_ sudah berjalan:
   ```bash
   docker-compose ps
   ```

### 2. Deploy Sistem Monitoring (Prometheus & Grafana)

1. Buka terminal dan masuk ke direktori `server/monitoring/`:
   ```bash
   cd server/monitoring
   ```
2. Jalankan _container_ Prometheus dan Grafana:
   ```bash
   docker-compose up -d
   ```

### Akses Layanan Lokal

- **Backend API**: [http://localhost:5001](http://localhost:5001)
- **Prometheus UI**: [http://localhost:9090](http://localhost:9090)
- **Grafana UI**: [http://localhost:3000](http://localhost:3000) (User: `administrator`, Pass: `changemeindproduction`)

_(Tear down: Gunakan perintah `docker-compose down` pada masing-masing folder)._

---

## JALUR B: Deployment menggunakan Kubernetes (Production)

Jalur ini digunakan apabila Anda ingin men-deploy arsitektur ke klaster server (VM) sungguhan.

### 1. Provisioning Virtual Machine dengan Terraform (`server/terraform`)

Terraform digunakan untuk menyewa/mencetak Virtual Machine secara otomatis yang akan dijadikan node klaster Kubernetes.

1. Masuk ke direktori terraform:
   ```bash
   cd server/terraform
   ```
2. Inisialisasi plugin Terraform:
   ```bash
   terraform init
   ```
3. Lihat rencana _provisioning_ (pastikan _cloud provider credential_ sudah diset):
   ```bash
   terraform plan
   ```
4. Eksekusi pembuatan _resources_:
   ```bash
   terraform apply -auto-approve
   ```
   _(Catatan: Setelah selesai, catat Public IP dari output terraform untuk dimasukkan ke file inventory Ansible)_.

### 2. Konfigurasi Server dengan Ansible (`server/ansible`)

Ansible bertugas menginstal dependensi dasar, mengatur _firewall_, menyiapkan _container runtime_, dan mengonfigurasi VM hingga menjadi klaster Kubernetes yang berjalan.

1. Masuk ke direktori ansible:
   ```bash
   cd server/ansible
   ```
2. Sesuaikan file inventory (misal `inventory/hosts`) dengan IP dari hasil Terraform.
3. Jalankan Ansible Playbook untuk mengonfigurasi VM:
   ```bash
   ansible-playbook -i inventory/hosts site.yml
   ```
   _(Setelah playbook selesai, klaster Kubernetes Anda sudah terinstal dan berjalan)._

### 3. Deploy Aplikasi ke Kubernetes (`backend/deployments`)

Setelah klaster menyala dan Anda telah menghubungkan `kubeconfig` (`~/.kube/config`) lokal Anda ke klaster, Anda bisa mulai menerapkan manifest.

1. Masuk ke direktori manifest deployment:
   ```bash
   cd backend/deployments
   ```
2. Terapkan (apply) objek _ConfigMap_ terlebih dahulu (termasuk config Blackbox):
   ```bash
   kubectl apply -f configmap.yaml
   kubectl apply -f blackbox-configmap.yaml
   ```
3. Terapkan _Deployment_ aplikasi (yang memuat container backend & sidecar blackbox):
   ```bash
   kubectl apply -f deployment.yaml
   ```
4. Expose aplikasi agar dapat diakses dari dalam klaster menggunakan _Service_:
   ```bash
   kubectl apply -f service.yaml
   ```
5. _(Opsional)_ Jika Anda menggunakan Ingress Traefik (Gateway API), terapkan routing HTTP agar aplikasi bisa diakses dari luar:
   ```bash
   cd ../ingress
   kubectl apply -f ingress.yaml
   kubectl apply -f httproute.yaml
   ```
6. Verifikasi pods dan service berjalan:
   ```bash
   kubectl get pods
   kubectl get svc
   ```
