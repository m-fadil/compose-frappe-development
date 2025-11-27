# Frappe Multi-Project Docker Setup

Setup development environment untuk multiple Frappe projects menggunakan shared infrastructure (Database & Redis).

## 🎯 Konsep Arsitektur

Arsitektur ini memisahkan infrastruktur dari aplikasi:

```
┌─────────────────────────────────────────────────────────────┐
│                   SHARED INFRASTRUCTURE                     │
│  ┌──────────┐  ┌───────────┐  ┌───────────┐  ┌──────────┐ │
│  │ MariaDB  │  │Redis Cache│  │Redis Queue│  │Redis S.IO│ │
│  └──────────┘  └───────────┘  └───────────┘  └──────────┘ │
│                    (Jalan 1x saja)                          │
└─────────────────────────────────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
   ┌────▼─────┐        ┌────▼─────┐        ┌────▼─────┐
   │Project 1 │        │Project 2 │        │Project 3 │
   │(Frappe+  │        │(ERPNext+ │        │(Custom   │
   │ Nginx)   │        │ Nginx)   │        │ Apps +   │
   │          │        │          │        │ Nginx)   │
   │Port 8080 │        │Port 8081 │        │Port 8082 │
   └──────────┘        └──────────┘        └──────────┘
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
├── docker-compose.infrastructure.yml   # Shared services
├── docker-compose.project1.yml         # Project 1
├── docker-compose.project2.yml         # Project 2
├── .env                                # Environment variables
├── apps/                               # Custom apps (optional)
│   ├── project1_app/
│   ├── project2_app/
│   └── shared_app/
└── README.md
```

## 🚀 Quick Start

### 1. Setup Infrastructure (Sekali Saja)

```bash
# Clone atau download files
git clone [your-repo-url]
cd frappe-docker

# Buat file .env
cat > .env << EOF
MYSQL_ROOT_PASSWORD=your_secure_password_here
ADMIN_PASSWORD=your_admin_password_here
EOF

# Start shared infrastructure
docker compose -f docker-compose.infrastructure.yml up -d

# Cek status
docker compose -f docker-compose.infrastructure.yml ps
```

### 2. Setup Project Pertama

```bash
# Copy template
cp docker-compose.project.yml docker-compose.alpha-fitness.yml

# Edit file dan ganti semua [project-name] dengan alpha-fitness
# Gunakan search & replace di editor Anda

# Start project
docker compose -f docker-compose.alpha-fitness.yml up -d

# Monitor logs
docker compose -f docker-compose.alpha-fitness.yml logs -f frappe-init-alpha-fitness

# Tunggu sampai selesai initialization
```

### 3. Akses Aplikasi

```bash
# Via Nginx (production-like)
http://localhost:8080

# Atau jalankan bench start untuk development
docker exec -it frappe-alpha-fitness bash
bench start
# Lalu akses: http://localhost:8001
```

**Login Credentials:**
- Username: `Administrator`
- Password: (sesuai ADMIN_PASSWORD di .env, default: `admin`)

## 📝 Cara Membuat Project Baru

### Step-by-Step:

```bash
# 1. Copy template
cp docker-compose.project.yml docker-compose.myproject.yml

# 2. Replace semua [project-name] dengan myproject
# Linux/Mac:
sed -i 's/\[project-name\]/myproject/g' docker-compose.myproject.yml

# Windows (gunakan editor):
# Find & Replace: [project-name] → myproject

# 3. Sesuaikan port agar tidak konflik
# Edit section ports di nginx-myproject:
#   ports:
#     - "8081:80"  # Gunakan 8081, 8082, dst (bukan 8080 lagi)

# 4. (Optional) Mount custom apps
# Edit section volumes di frappe-myproject:
#   volumes:
#     - ~/Projects/frappe/apps/myapp:/home/frappe/frappe-bench/apps/myapp:z

# 5. Start project
docker compose -f docker-compose.myproject.yml up -d

# 6. Cek logs
docker compose -f docker-compose.myproject.yml logs -f
```

## 🛠️ Management Commands

### Infrastructure Commands

```bash
# Status
docker compose -f docker-compose.infrastructure.yml ps

# Logs
docker compose -f docker-compose.infrastructure.yml logs -f

# Restart
docker compose -f docker-compose.infrastructure.yml restart

# Stop (HATI-HATI: Akan stop semua project)
docker compose -f docker-compose.infrastructure.yml down

# Backup Database
docker exec frappe-mariadb mysqldump -uroot -p[password] --all-databases > backup-$(date +%Y%m%d).sql

# Restore Database
docker exec -i frappe-mariadb mysql -uroot -p[password] < backup-20241126.sql
```

### Project Commands

```bash
# Ganti [project] dengan nama project Anda (contoh: alpha-fitness)

# Start
docker compose -f docker-compose.[project].yml up -d

# Stop
docker compose -f docker-compose.[project].yml down

# Restart
docker compose -f docker-compose.[project].yml restart

# Logs
docker compose -f docker-compose.[project].yml logs -f

# Remove (termasuk volumes)
docker compose -f docker-compose.[project].yml down -v
```

### Development Commands

```bash
# Enter container
docker exec -it frappe-[project] bash

# Start bench (development server)
bench start

# Create new app
bench new-app myapp

# Install app to site
bench --site [project].localhost install-app myapp

# Get app from git
bench get-app [app-name] [git-url]

# Migrate
bench --site [project].localhost migrate

# Clear cache
bench clear-cache

# Console
bench --site [project].localhost console

# Update bench & apps
bench update

# Backup
bench --site [project].localhost backup

# Restore
bench --site [project].localhost restore /path/to/backup.sql
```

## 🔧 Configuration Guide

### Port Allocation

Untuk menghindari konflik, alokasikan port berbeda untuk setiap project:

| Project        | Nginx HTTP | Dev Frontend | Dev Backend |
|----------------|------------|--------------|-------------|
| Project 1      | 8080       | 8001         | 9001        |
| Project 2      | 8081       | 8002         | 9002        |
| Project 3      | 8082       | 8003         | 9003        |
| Infrastructure | 3306       | -            | -           |

### Environment Variables

Buat file `.env` di root directory:

```bash
# Database
MYSQL_ROOT_PASSWORD=super_secure_password_123

# Frappe Admin
ADMIN_PASSWORD=admin_secure_password

# Cloudflare (optional)
CLOUDFLARE_TOKEN=your_cloudflare_tunnel_token
```

### Custom Apps Development

Untuk development dengan custom apps:

```yaml
# Di docker-compose.[project].yml, section frappe-[project]:
volumes:
  - frappe-bench-[project]:/home/frappe/frappe-bench
  # Mount apps untuk development
  - ~/Projects/frappe/apps/frappe:/home/frappe/frappe-bench/apps/frappe:z
  - ~/Projects/frappe/apps/myapp:/home/frappe/frappe-bench/apps/myapp:z
```

**Note:** `:z` flag diperlukan untuk SELinux (Fedora/RHEL/CentOS)

## 🔍 Troubleshooting

### Infrastructure tidak start

```bash
# Cek logs
docker compose -f docker-compose.infrastructure.yml logs

# Cek apakah port 3306 sudah dipakai
sudo ss -tulpn | grep 3306

# Stop service yang conflict
sudo systemctl stop mariadb  # atau mysql
```

### Project initialization gagal

```bash
# Cek logs detail
docker compose -f docker-compose.[project].yml logs frappe-init-[project]

# Hapus volume dan coba lagi
docker compose -f docker-compose.[project].yml down -v
docker compose -f docker-compose.[project].yml up -d
```

### Database connection error

```bash
# Pastikan infrastructure running
docker ps | grep frappe-mariadb

# Test connection
docker exec -it frappe-mariadb mysql -uroot -p

# Cek dari container frappe
docker exec -it frappe-[project] bash
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

# Kill process atau ubah port di docker-compose file
```

### Nginx 404 Error

```bash
# Regenerate nginx config
docker exec -it frappe-[project] bash
bench setup nginx

# Restart nginx
docker compose -f docker-compose.[project].yml restart nginx-[project]
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

# Cek logs error
docker compose -f docker-compose.infrastructure.yml logs --tail=100 | grep -i error
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

# Sites backup (untuk setiap project)
docker exec frappe-[project] bench --site [project].localhost backup
```

## 🔄 Update & Maintenance

### Update Frappe

```bash
# Enter container
docker exec -it frappe-[project] bash

# Update bench
bench update

# Update specific app
bench update --apps frappe

# Migrate after update
bench --site [project].localhost migrate
```

### Update Docker Images

```bash
# Pull latest images
docker compose -f docker-compose.infrastructure.yml pull
docker compose -f docker-compose.[project].yml pull

# Recreate containers
docker compose -f docker-compose.infrastructure.yml up -d
docker compose -f docker-compose.[project].yml up -d
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
