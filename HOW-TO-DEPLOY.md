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

Konfigurasi Docker Compose saat ini telah dirancang terintegrasi; Backend, Database (PostgreSQL), dan Monitoring (Prometheus & Grafana) berada dalam satu _shared network_ (`book-app-network`).

### 1. Deploy Backend dan Database (PostgreSQL)

Tahap pertama adalah menjalankan layanan utama (Backend API) beserta dependensi basis datanya.

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
   _(Catatan: Menjalankan backend akan secara otomatis mendirikan network `book-app-network` yang dibutuhkan oleh komponen monitoring nantinya)._

### 2. Deploy Sistem Monitoring (Prometheus & Grafana)

Sistem monitoring akan men-_scrape_ metrik langsung dari aplikasi backend secara otomatis (via endpoint `/metrics`) dan memuat _dashboard_ yang telah di-_provision_.

1. Buka terminal dan masuk ke direktori `server/monitoring/`:
   ```bash
   cd server/monitoring
   ```
2. Pastikan network `book-app-network` dari tahap sebelumnya sudah ada, lalu jalankan:
   ```bash
   docker-compose up -d
   ```

### Akses Layanan Lokal

- **Backend API**: [http://localhost:5001](http://localhost:5001)
- **Prometheus UI**: [http://localhost:9090](http://localhost:9090)
- **Grafana UI**: [http://localhost:3000](http://localhost:3000)
  - Login default (jika diminta): User: `administrator`, Pass: `changemeindproduction`
  - Buka menu _Dashboards_ untuk melihat panel "Book App Backend Monitoring" yang telah terpasang otomatis.

_(Tear down: Gunakan perintah `docker-compose down` pada masing-masing folder)._

---

## JALUR B: Deployment menggunakan Kubernetes (Production)

Jalur ini digunakan apabila Anda ingin men-deploy arsitektur ke klaster server (VM) sungguhan.

### 1. K3s Cluster Auth (SRE Access)

Setelah klaster dibuat, Anda sangat disarankan untuk mengatur akses SRE berbasis Service Account dan Bearer Token daripada menggunakan admin root `kubeconfig`.

- Lihat panduannya di: **[server/k3s/AUTH.md](server/k3s/AUTH.md)**

### 2. Manual Kubectl Apply

Anda dapat menerapkan manifest deployment ke kluster secara manual:

1. Masuk ke direktori manifest deployment:
   ```bash
   cd backend/deployments
   ```
2. Terapkan objek Kubernetes berurutan:
   ```bash
   kubectl apply -f configmap.yaml
   kubectl apply -f deployment.yaml
   kubectl apply -f service.yaml
   ```

---

## Continuous Integration (CI/CD Pipeline)

Repositori ini telah dilengkapi dengan **GitHub Actions pipeline** (`.github/workflows/backend-ci.yml`) yang berjalan otomatis saat ada _Push_ atau _Pull Request_ ke _branch_ `main`.

Tahapan pipeline:

1. **Lint**: Memeriksa kode menggunakan `flake8`.
2. **Test**: Menjalankan unit test dengan `pytest`.
3. **Build**: Melakukan build _image docker_ untuk proses testing.
4. **Scan (Security)**: Menjalankan pemindaian kerentanan _image_ menggunakan **Trivy**. Pipeline akan otomatis gagal (_break_) jika ditemukan kerentanan berlevel `CRITICAL` atau `HIGH`.
5. **Push**: Push _image_ final yang aman ke Docker Hub.
