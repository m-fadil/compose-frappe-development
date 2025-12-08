# Frappe Multi-Project Docker Setup

Setup development environment untuk multiple Frappe projects menggunakan shared infrastructure (Database & Redis).

## 🎯 Konsep Arsitektur

Arsitektur ini memisahkan infrastruktur dari aplikasi:

```
┌─────────────────────────────────────────────────────────────┐
│                   SHARED INFRASTRUCTURE                     │
│  ┌──────────┐  ┌───────────┐  ┌───────────┐  ┌──────────┐   │
│  │ MariaDB  │  │Redis Cache│  │Redis Queue│  │Redis S.IO│   │
│  └──────────┘  └───────────┘  └───────────┘  └──────────┘   │
│                    (Jalan 1x saja)                          │
└─────────────────────────────────────────────────────────────┘
                          │
         ┌────────────────┼────────────────┐
         │                │                │
    ┌────▼─────┐    ┌────▼─────┐    ┌────▼─────┐
    │Project 1 │    │Project 2 │    │Project 3 │
    │(Frappe+  │    │(ERPNext+ │    │(Custom   │
    │ Nginx)   │    │ Nginx)   │    │ Apps +   │
    │          │    │          │    │ Nginx)   │
    │Port 8080 │    │Port 8081 │    │Port 8082 │
    └──────────┘    └──────────┘    └──────────┘
```

### Keuntungan Arsitektur Ini:

✅ **Resource Efficient**: Database & Redis hanya 1 instance untuk semua project
✅ **Easy Management**: Start/stop project secara independen
✅ **Cost Effective**: Hemat memory & CPU
✅ **Scalable**: Mudah menambah project baru
✅ **Isolated**: Setiap project punya volume & config sendiri

## 📁 Struktur Direktori

```
frappe-docker/
├── docker-compose.yml                  # Shared infrastructure services (MariaDB, Redis)
├── project/
│   └── docker-compose.yml              # Template untuk setiap project Frappe
├── .env.example                        # Contoh file konfigurasi environment
├── apps/                               # Custom apps (optional)
│   ├── project1_app/
│   ├── project2_app/
│   └── shared_app/
└── my-frappe-project/                  # Contoh direktori untuk Project 1
    └── docker-compose.yml              # Konfigurasi Docker Compose untuk Project 1
```

## 🚀 Quick Start

### 1. Setup Infrastructure (Sekali Saja)

```bash
# Clone atau download files
git clone [your-repo-url]
cd frappe-docker

# Buat file .env untuk infrastruktur dari contoh
cp .env.example .env

# Edit file .env sesuai kebutuhan (ubah MYSQL_ROOT_PASSWORD)
nano .env

# Start shared infrastructure
docker compose up -d

# Cek status
docker compose ps
```

### 2. Setup Project Pertama

```bash
# Buat direktori baru untuk project Anda
mkdir my-frappe-project
cd my-frappe-project

# Copy template docker-compose.yml dari direktori 'project'
cp ../project/docker-compose.yml docker-compose.yml

# Buat file .env dan sesuaikan SITE_NAME dengan nama site Anda
# Contoh isi .env:
# MYSQL_ROOT_PASSWORD=your_secure_password
# ADMIN_PASSWORD=your_admin_password
# SITE_NAME=alpha-fitness.localhost

# Sesuaikan port Nginx (misal: "8080:80") agar tidak konflik dengan project lain

# Kembali ke root directory frappe-docker
cd ..

# Start project
docker compose -f my-frappe-project/docker-compose.yml up -d

# Monitor logs (ganti 'frappe-init' dengan nama service init Anda jika berbeda)
docker compose -f my-frappe-project/docker-compose.yml logs -f frappe-init

# Tunggu sampai selesai initialization
```

### 3. Akses Aplikasi

```bash
# Via Nginx (production-like)
http://localhost:8080

# Atau jalankan bench start untuk development
docker exec -it my-frappe-project-frappe-1 bash # Ganti dengan nama container frappe Anda
bench start
# Lalu akses: http://localhost:8000 (jika port 8000 di-expose)
```

**Login Credentials:**
- Username: `Administrator`
- Password: (sesuai ADMIN_PASSWORD di .env project, default: `admin`)

## 📝 Cara Membuat Project Baru

### Step-by-Step:

```bash
# 1. Buat direktori baru untuk project Anda (misal: myproject)
mkdir myproject
cd myproject

# 2. Copy template docker-compose.yml dari direktori 'project'
cp ../project/docker-compose.yml docker-compose.yml

# 3. Buat file .env dan sesuaikan variabel berikut:
#    - SITE_NAME: Nama site Anda (misal: myproject.localhost)
#    - ADMIN_PASSWORD: Password untuk user Administrator
#    - MYSQL_ROOT_PASSWORD: Harus sama dengan yang di infrastruktur
#    Sesuaikan port Nginx agar tidak konflik dengan project lain (misal: "8081:80")

# 4. (Optional) Mount custom apps
#    Edit section volumes di service 'frappe' di docker-compose.yml Anda:
#      volumes:
#        - frappe-bench:/home/frappe/frappe-bench
#        # Mount apps untuk development
#        - ~/Projects/frappe/apps/myapp:/home/frappe/frappe-bench/apps/myapp:z

# 5. Kembali ke root directory frappe-docker
cd ..

# 6. Start project
docker compose -f myproject/docker-compose.yml up -d

# 7. Cek logs
docker compose -f myproject/docker-compose.yml logs -f
```

## 🛠️ Management Commands

### Infrastructure Commands (dari root directory frappe-docker)

```bash
# Status
docker compose ps

# Logs
docker compose logs -f

# Restart
docker compose restart

# Stop (HATI-HATI: Akan stop semua service infrastruktur)
docker compose down

# Backup Database
docker exec frappe-mariadb mysqldump -uroot -p${MYSQL_ROOT_PASSWORD:-frappe_root_pass_123} --all-databases > backup-$(date +%Y%m%d).sql

# Restore Database
docker exec -i frappe-mariadb mysql -uroot -p${MYSQL_ROOT_PASSWORD:-frappe_root_pass_123} < backup-20241126.sql
```

### Project Commands (dari root directory frappe-docker, ganti [project-dir] dengan nama direktori project Anda)

```bash
# Ganti [project-dir] dengan nama direktori project Anda (contoh: my-frappe-project)

# Start
docker compose -f [project-dir]/docker-compose.yml up -d

# Stop
docker compose -f [project-dir]/docker-compose.yml down

# Restart
docker compose -f [project-dir]/docker-compose.yml restart

# Logs
docker compose -f [project-dir]/docker-compose.yml logs -f

# Remove (termasuk volumes)
docker compose -f [project-dir]/docker-compose.yml down -v
```

### Development Commands (setelah masuk ke container frappe project)

```bash
# Enter container (ganti [project-dir]-frappe-1 dengan nama container frappe Anda)
docker exec -it [project-dir]-frappe-1 bash

# Start bench (development server)
bench start

# Create new app
bench new-app myapp

# Install app to site (ganti [project-name].localhost dengan nama site Anda)
# Nama site dapat dilihat di file .env project Anda (variabel SITE_NAME)
bench --site [project-name].localhost install-app myapp

# Get app from git
bench get-app [app-name] [git-url]

# Migrate
# Nama site dapat dilihat di file .env project Anda (variabel SITE_NAME)
bench --site [project-name].localhost migrate

# Clear cache
bench clear-cache

# Console
bench --site [project-name].localhost console

# Update bench & apps
bench update

# Backup
# Nama site dapat dilihat di file .env project Anda (variabel SITE_NAME)
bench --site [project-name].localhost backup

# Restore
# Nama site dapat dilihat di file .env project Anda (variabel SITE_NAME)
bench --site [project-name].localhost restore /path/to/backup.sql
```

## 🔧 Configuration Guide

### Port Allocation

Untuk menghindari konflik, alokasikan port berbeda untuk setiap project:

| Project        | Nginx HTTP | Dev Frontend | Dev Backend |
|----------------|------------|--------------|-------------|
| Project 1      | 8080       | 8000         | 9000        |
| Project 2      | 8081       | 8001         | 9001        |
| Project 3      | 8082       | 8002         | 9002        |
| Infrastructure | 3306       | -            | -           |

### Environment Variables

Buat file `.env` di root directory `frappe-docker`:

```bash
# Database
MYSQL_ROOT_PASSWORD=super_secure_password_123
```

Catatan: Setiap project akan memiliki file `.env` tersendiri di direktori projectnya dengan variabel tambahan seperti `ADMIN_PASSWORD`, `SITE_NAME`, dan `CLOUDFLARE_TOKEN`.

### Custom Apps Development

Untuk development dengan custom apps, edit `docker-compose.yml` di direktori project Anda (misal: `my-frappe-project/docker-compose.yml`), di bagian service `frappe`:

```yaml
volumes:
  - frappe-bench:/home/frappe/frappe-bench
  # Mount apps untuk development
  - ~/Projects/frappe/apps/frappe:/home/frappe/frappe-bench/apps/frappe:z
  - ~/Projects/frappe/apps/myapp:/home/frappe/frappe-bench/apps/myapp:z
```

**Note:** `:z` flag diperlukan untuk SELinux (Fedora/RHEL/CentOS)

## 🔍 Troubleshooting

### Infrastructure tidak start

```bash
# Cek logs
docker compose logs

# Cek apakah port 3306 sudah dipakai
sudo ss -tulpn | grep 3306

# Stop service yang conflict
sudo systemctl stop mariadb  # atau mysql
```

### Project initialization gagal

```bash
# Cek logs detail (ganti [project-dir] dengan nama direktori project Anda)
docker compose -f [project-dir]/docker-compose.yml logs frappe-init

# Hapus volume dan coba lagi
docker compose -f [project-dir]/docker-compose.yml down -v
docker compose -f [project-dir]/docker-compose.yml up -d
```

### Database connection error

```bash
# Pastikan infrastructure running
docker ps | grep frappe-mariadb

# Test connection dari container mariadb
docker exec -it frappe-mariadb mysql -uroot -p

# Cek dari container frappe (ganti [project-dir]-frappe-1 dengan nama container frappe Anda)
docker exec -it [project-dir]-frappe-1 bash
mysql -h frappe-mariadb -uroot -p
```

### Permission denied saat mount volumes

```bash
# Set SELinux context (Linux)
chcon -Rt svirt_sandbox_file_t ~/Projects/frappe/apps/

# Atau disable SELinux temporarily (not recommended)
sudo setenforce 0
```

### Port already in use

```bash
# Cek port yang digunakan
sudo ss -tulpn | grep 8080

# Kill process atau ubah port di docker-compose file project Anda
```

### Nginx 404 Error

Pastikan SITE_NAME di file .env project Anda sesuai dengan konfigurasi site yang ada.

```bash
# Regenerate nginx config (ganti [project-dir]-frappe-1 dengan nama container frappe Anda)
docker exec -it [project-dir]-frappe-1 bash
bench setup nginx

# Restart nginx (ganti [project-dir] dengan nama direktori project Anda)
docker compose -f [project-dir]/docker-compose.yml restart nginx
```

## 📊 Monitoring

### Resource Usage

```bash
# Lihat resource usage semua container
docker stats

# Lihat resource usage infrastructure
docker stats frappe-mariadb frappe-redis-cache frappe-redis-queue

# Lihat disk usage
docker system df -v
```

### Health Check

```bash
# Cek health semua services
docker ps --format "table {{.Names}}\t{{.Status}}"

# Cek logs error infrastructure
docker compose logs --tail=100 | grep -i error
```

## 🔐 Security Best Practices

### Production Checklist:

- [ ] Ubah semua default passwords
- [ ] Gunakan strong passwords di `.env`
- [ ] Jangan commit `.env` ke git (sudah ada di `.gitignore`)
- [ ] Disable developer mode: `bench set-config developer_mode 0`
- [ ] Setup SSL/TLS untuk production
- [ ] Batasi port exposure (hapus port mapping yang tidak perlu)
- [ ] Regular database backup
- [ ] Update images secara berkala
- [ ] Monitor logs untuk aktivitas mencurigakan
- [ ] Gunakan firewall untuk membatasi akses

### Backup Strategy:

```bash
# Backup script example
#!/bin/bash
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="./backups"

# Database backup
docker exec frappe-mariadb mysqldump -uroot -p$MYSQL_ROOT_PASSWORD --all-databases | gzip > $BACKUP_DIR/db_$DATE.sql.gz

# Sites backup (untuk setiap project, ganti [project-dir]-frappe-1 dan [project-name].localhost)
# [project-name].localhost harus sesuai dengan SITE_NAME di file .env project Anda
docker exec frappe-[project-dir]-frappe-1 bench --site [project-name].localhost backup
```

## 🔄 Update & Maintenance

### Update Frappe (setelah masuk ke container frappe project)

```bash
# Enter container (ganti [project-dir]-frappe-1 dengan nama container frappe Anda)
docker exec -it [project-dir]-frappe-1 bash

# Update bench
bench update

# Update specific app
bench update --apps frappe

# Migrate after update
# [project-name].localhost harus sesuai dengan SITE_NAME di file .env project Anda
bench --site [project-name].localhost migrate
```

### Update Docker Images

```bash
# Pull latest images untuk infrastruktur
docker compose pull

# Pull latest images untuk project (ganti [project-dir] dengan nama direktori project Anda)
docker compose -f [project-dir]/docker-compose.yml pull

# Recreate containers untuk infrastruktur
docker compose up -d

# Recreate containers untuk project (ganti [project-dir] dengan nama direktori project Anda)
docker compose -f [project-dir]/docker-compose.yml up -d
```

## 💻 Optional Development Tools

### Install Helix Editor

Untuk memasang Helix Editor, jalankan perintah berikut:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/m-fadil/compose-frappe-development/refs/heads/main/install_helix.sh)
```

## 📚 Additional Resources

- [Frappe Framework Documentation](https://frappeframework.com/docs)
- [Frappe Docker GitHub](https://github.com/frappe/frappe_docker)
- [ERPNext Documentation](https://docs.erpnext.com/)
- [Docker Documentation](https://docs.docker.com/)

## 🤝 Contributing

Kontribusi sangat diterima! Silakan:

1. Fork repository ini
2. Buat branch untuk fitur Anda (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push ke branch (`git push origin feature/AmazingFeature`)
5. Buat Pull Request

## 📄 License

Sesuaikan dengan license project Anda.

## 💬 Support

Jika Anda menemukan bug atau punya pertanyaan:

- Buat [Issue](https://github.com/your-repo/issues)
- Atau hubungi via [Email](mailto:your-email@example.com)

## 🎯 Roadmap

- [ ] Add monitoring dengan Prometheus & Grafana
- [ ] Add automated backup script
- [ ] Add CI/CD pipeline example
- [ ] Add Kubernetes deployment option
- [ ] Add production deployment guide

---
