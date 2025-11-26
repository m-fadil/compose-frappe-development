# Frappe Development Environment with Docker

Dokumentasi lengkap untuk setup development environment Frappe Framework menggunakan Docker Compose.

## 📋 Daftar Isi

- [Persyaratan](#persyaratan)
- [Struktur Project](#struktur-project)
- [Komponen Services](#komponen-services)
- [Cara Penggunaan](#cara-penggunaan)
- [Konfigurasi](#konfigurasi)
- [Troubleshooting](#troubleshooting)

## 🔧 Persyaratan

- Docker Engine 20.10+
- Docker Compose v2.0+
- Minimal 4GB RAM
- 10GB disk space

## 📁 Struktur Project

```
project-root/
├── docker-compose.yml
├── apps/
│   ├── frappe/
│   ├── your_custom_app/
│   └── ...
└── README.md
```

## 🏗️ Komponen Services

### 1. MariaDB
Database server untuk Frappe
- **Image**: mariadb:11.8
- **Port**: 3306
- **Root Password**: 123 (ubah di production!)
- **Character Set**: utf8mb4

### 2. Redis Cache & Queue
Cache dan queue management
- **redis-cache**: Untuk caching aplikasi
- **redis-queue**: Untuk background jobs

### 3. Frappe Init
Container initialization untuk setup awal bench
- Setup bench dengan Frappe v15
- Membuat site development
- Konfigurasi database dan redis
- Setup nginx

### 4. Frappe
Container utama untuk development
- Mount custom apps dari host
- DNS configuration untuk connectivity
- Developer mode enabled

### 5. Nginx
Web server sebagai reverse proxy
- Serve static files
- Route requests ke Frappe

### 6. Cloudflared (Optional)
Tunnel untuk expose local development ke internet

## 🚀 Cara Penggunaan

### Setup Awal

1. **Clone repository dan masuk ke direktori project**
   ```bash
   cd ~/Projects/frappe/your_project
   ```

2. **Buat struktur folder untuk apps**
   ```bash
   mkdir -p ~/Projects/frappe/apps
   ```

3. **Start services**
   ```bash
   docker compose up -d
   ```

4. **Cek logs initialization**
   ```bash
   docker compose logs -f frappe-init
   ```
   Tunggu hingga muncul pesan "Initialization complete!"

### Development Workflow

1. **Masuk ke container Frappe**
   ```bash
   docker compose exec frappe bash
   ```

2. **Membuat custom app baru**
   ```bash
   bench new-app app_name
   ```

3. **Install app ke site**
   ```bash
   bench --site development.localhost install-app app_name
   ```

4. **Start development server**
   ```bash
   bench start
   ```

5. **Akses aplikasi**
   - Frontend: http://development.localhost:8000
   - Backend: http://development.localhost:9000

### Command Berguna

```bash
# Restart semua services
docker compose restart

# Stop semua services
docker compose down

# Stop dan hapus volumes (HATI-HATI: data akan hilang)
docker compose down -v

# Lihat logs service tertentu
docker compose logs -f frappe

# Update bench dan apps
docker compose exec frappe bench update

# Backup site
docker compose exec frappe bench --site development.localhost backup

# Restore backup
docker compose exec frappe bench --site development.localhost restore /path/to/backup

# Migrate database
docker compose exec frappe bench --site development.localhost migrate

# Clear cache
docker compose exec frappe bench clear-cache
```

## ⚙️ Konfigurasi

### Custom Apps

Edit `docker-compose.yml` pada bagian volumes service `frappe`:

```yaml
volumes:
  - frappe-bench-data:/home/frappe/frappe-bench
  - /path/to/your/app1:/home/frappe/frappe-bench/apps/app1:z
  - /path/to/your/app2:/home/frappe/frappe-bench/apps/app2:z
```

### Environment Variables

Ubah password default di production:

```yaml
environment:
  MYSQL_ROOT_PASSWORD: your_secure_password
```

Dan sesuaikan command di `frappe-init`:

```bash
bench new-site --db-root-password your_secure_password ...
```

### Port Mapping

Uncomment untuk expose port ke host:

```yaml
ports:
  - "8000:8000"  # Frontend
  - "9000:9000"  # Backend/Socketio
```

### Cloudflare Tunnel

Ganti token dengan token Anda sendiri atau hapus service jika tidak diperlukan:

```yaml
command: tunnel --no-autoupdate run --token YOUR_TOKEN_HERE
```

## 🔍 Troubleshooting

### Container frappe-init tidak complete

```bash
# Cek logs
docker compose logs frappe-init

# Restart initialization
docker compose down
docker volume rm your_project_frappe-bench-data
docker compose up -d
```

### Permission Issues

```bash
# Masuk sebagai root
docker compose exec -u root frappe bash

# Fix permissions
chown -R frappe:frappe /home/frappe/frappe-bench
```

### Database Connection Error

```bash
# Cek apakah MariaDB sudah ready
docker compose exec mariadb mysqladmin -uroot -p123 ping

# Test koneksi dari container frappe
docker compose exec frappe bench --site development.localhost mariadb
```

### Nginx 404 Error

```bash
# Regenerate nginx config
docker compose exec frappe bench setup nginx
docker compose restart nginx
```

### Port Already in Use

```bash
# Cek port yang digunakan
sudo ss -tulpn | grep :8000

# Kill process atau ubah port mapping di docker-compose.yml
```

## 🔐 Security Notes

⚠️ **PENTING untuk Production:**

1. Ubah semua password default
2. Gunakan environment variables untuk credentials
3. Enable SSL/TLS
4. Batasi network exposure
5. Regular backup database
6. Update image secara berkala

## 📚 Referensi

- [Frappe Framework Documentation](https://frappeframework.com/docs)
- [Frappe Docker Hub](https://hub.docker.com/r/frappe/bench)
- [ERPNext Documentation](https://docs.erpnext.com/)

## 📄 License

Sesuaikan dengan license project Anda.

## 🤝 Contributing

Kontribusi sangat diterima! Silakan buat issue atau pull request.

---

**Dibuat dengan ❤️ untuk Frappe Community**
