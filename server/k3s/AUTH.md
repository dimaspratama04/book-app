# Kubernetes Authentication Guide (Service Account)

Panduan ini menjelaskan cara mengonfigurasi akses ke Kubernetes/k3s cluster menggunakan _Service Account_ bernama `sre` dan _Bearer Token_. Ini adalah praktik yang jauh lebih aman untuk memberikan akses ke sistem CI/CD atau anggota tim tanpa harus mendistribusikan kredensial admin utama (_root kubeconfig_).

## 1. Membuat Service Account `sre`

Langkah pertama adalah membuat sebuah _Service Account_ di dalam kluster Anda. Kita akan membuatnya di _namespace_ `kube-system`:

```bash
kubectl create serviceaccount sre -n kube-system
```

## 2. Memberikan Izin (Role Binding)

Selanjutnya, kita perlu menetapkan batasan hak akses (_permissions_) kepada akun `sre` tersebut. Sebagai contoh, jika tim SRE membutuhkan akses penuh sebagai administrator kluster:

```bash
kubectl create clusterrolebinding sre-cluster-admin-binding \
  --clusterrole=cluster-admin \
  --serviceaccount=kube-system:sre
```
*(Ganti `cluster-admin` dengan _role_ yang lebih spesifik seperti `view` atau `edit` jika Anda ingin menerapkan prinsip _Least Privilege_).*

## 3. Mendapatkan Bearer Token

Mulai Kubernetes v1.24 ke atas, _Service Account_ tidak lagi memproduksi token secara otomatis saat dibuat. Anda harus meng-*generate* tokennya.

**Opsi A: Menggunakan Token Jangka Pendek/Terbatas (Praktik Terbaik)**
```bash
# Membuat token yang berlaku selama 1 tahun (8760 jam)
kubectl create token sre -n kube-system --duration=8760h
```
*(Perintah ini akan langsung mencetak panjang string token di terminal. Salin token tersebut).*

**Opsi B: Menggunakan Token Permanen (Long-lived Token)**
Jika Anda membutuhkan token yang tidak pernah _expired_:
```bash
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Secret
metadata:
  name: sre-token
  namespace: kube-system
  annotations:
    kubernetes.io/service-account.name: sre
type: kubernetes.io/service-account-token
EOF
```
Lalu ekstrak tokennya dengan cara:
```bash
kubectl get secret sre-token -n kube-system -o jsonpath='{.data.token}' | base64 --decode; echo
```

## 4. Mengonfigurasi `kubeconfig` di Mesin Klien

Setelah Anda menyalin **Bearer Token** dari langkah 3 dan mengetahui **IP/URL API Server** kluster k3s Anda, jalankan perintah-perintah berikut di mesin klien/laptop Anda untuk mengatur (setup) akses `kubectl`:

```bash
# 1. Daftarkan kluster Anda (ganti IP dan port sesuai konfigurasi API server K3s)
kubectl config set-cluster k3s-cluster \
  --server=https://<K3S_IP_ADDRESS>:6443 \
  --insecure-skip-tls-verify=true

# 2. Daftarkan kredensial user (sre) dengan memasukkan token
kubectl config set-credentials sre-user \
  --token="<MASUKKAN_BEARER_TOKEN_YANG_DISALIN_DI_SINI>"

# 3. Buat sebuah konteks (context) yang memetakan user ke kluster
kubectl config set-context k3s-sre-context \
  --cluster=k3s-cluster \
  --user=sre-user

# 4. Gunakan konteks tersebut sebagai default
kubectl config use-context k3s-sre-context
```

**Selesai!** 
Sekarang coba jalankan perintah `kubectl get nodes`. Klien Anda akan langsung menghubungi kluster menggunakan otentikasi dari _Service Account_ `sre` yang diwakili oleh _Bearer Token_ tersebut.
