# 💅 Coucou Beauté – Plateforme Beauté & Bien-être

[![Production Ready](https://img.shields.io/badge/Status-Production%20Ready-success)](https://github.com/yourusername/coucou_beaute)
[![Mobile Responsive](https://img.shields.io/badge/Mobile-Responsive-blue)](./MOBILE_RESPONSIVE.md)
[![HTTPS](https://img.shields.io/badge/HTTPS-Configured-green)](./HTTPS_SETUP.md)
[![Auto Deploy](https://img.shields.io/badge/Deploy-Automated-orange)](./CRON_AUTO_DEPLOY.md)

Plateforme complète de réservation de services de beauté à domicile avec:
- 🌐 **Backend Django REST** (JWT, PostgreSQL, uploads, notifications FCM)
- 📱 **Application Mobile Flutter** (Clean Architecture, Riverpod, GoRouter, i18n FR/AR/EN)
- 💻 **Interface Web Responsive** (100% mobile-optimized, touch-friendly)
- 🐳 **Infrastructure Docker** (production-ready, healthchecks, auto-scaling)
- 🤖 **Déploiement Automatique** (cron-based, zero-downtime)

---

## 🚀 Démarrage Rapide

### Production (Docker)

1. **Configuration initiale**:
```bash
# Sur le serveur
cd /opt/coucou_beaute
sudo bash quick-setup.sh
```

2. **Déploiement**:
```bash
sudo bash deploy.sh
```

3. **Accès au site**:
- Web: `https://your-domain.com/` (ou `https://196.203.120.35/`)
- API: `https://your-domain.com/api/`
- Admin: `https://your-domain.com/admin/`

### Développement Local

```bash
# Copier les variables d'environnement
cp backend/env.example backend/.env

# Lancer avec Docker
docker-compose up --build

# Accès
# - Web: http://localhost:8000/
# - API: http://localhost:8000/api/
```

## Démarrage backend (hors Docker)

```bash
python -m venv .venv && . .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r backend/requirements.txt
cp env.example .env
python backend/manage.py migrate
python backend/manage.py createsuperuser
python backend/manage.py runserver 0.0.0.0:8000
```

## Flutter

1. Installer Flutter 3.x
2. Dans `flutter_app/`:
```bash
flutter pub get
flutter run
```

## Structure

- Apps backend: `users`, `clients`, `pros`, `services_app`, `appointments`, `reviews_app`, `notifications_app`, `search_app`, `subscriptions`
- Endpoints clés (préfixe `/api/`): auth, clients, pros, search, notifications, admin-api

---

## ✨ Fonctionnalités

### 🌐 Frontend Web
- ✅ **100% Responsive** - Optimisé iOS, Android, Desktop
- ✅ **Touch-Friendly** - Touch targets 44px (Apple guidelines)
- ✅ **Performance** - Animations optimisées mobile
- ✅ **Accessibilité** - Support reduced motion, screen readers

### 🔐 Backend Django
- ✅ **Authentification JWT** (`djangorestframework-simplejwt`)
- ✅ **Uploads Fichiers** - Photos, documents (10MB max)
- ✅ **Notifications Push** - FCM integration
- ✅ **API REST** - Endpoints documentés
- ✅ **Admin Dashboard** - Interface de gestion

### 📱 Application Mobile
- ✅ **Flutter 3.x** - iOS & Android
- ✅ **Clean Architecture** - Scalable, testable
- ✅ **State Management** - Riverpod
- ✅ **i18n** - Français, Arabe, Anglais (RTL support)
- ✅ **Navigation** - GoRouter

### 🐳 Infrastructure
- ✅ **Docker Compose** - Multi-container orchestration
- ✅ **PostgreSQL** - Base de données robuste
- ✅ **Nginx** - Reverse proxy, HTTPS, static/media serving
- ✅ **Healthchecks** - Auto-restart services
- ✅ **Volumes Persistants** - Data safety

### 🤖 DevOps
- ✅ **Auto-déploiement** - Cron-based, détection commits
- ✅ **Zero Downtime** - Rolling deployments
- ✅ **Logs Centralisés** - Debugging facilité
- ✅ **Scripts Automatisés** - Setup, deploy, monitoring

---

## 📚 Documentation

| Document | Description |
|----------|-------------|
| **[FINAL_MOBILE_SUCCESS.md](./FINAL_MOBILE_SUCCESS.md)** | 🎊 **RAPPORT FINAL - 100% Mobile Ready** |
| [COMPLETE_MOBILE_REPORT.md](./COMPLETE_MOBILE_REPORT.md) | 📱 Rapport complet global (42 fichiers) |
| [ADMINPANEL_MOBILE.md](./ADMINPANEL_MOBILE.md) | 🎛️ Guide adminpanel responsive (23 fichiers) |
| [ADMINPANEL_MOBILE_SUMMARY.md](./ADMINPANEL_MOBILE_SUMMARY.md) | 📋 Résumé rapide adminpanel mobile |
| [ABSOLUTE_FINAL_REPORT.md](./ABSOLUTE_FINAL_REPORT.md) | 🎉 Rapport front_web mobile (19 fichiers) |
| [CRON_AUTO_DEPLOY.md](./CRON_AUTO_DEPLOY.md) | 🤖 Configuration auto-déploiement |
| [HTTPS_SETUP.md](./HTTPS_SETUP.md) | 🔐 Configuration SSL/TLS Let's Encrypt |
| [DEPLOYMENT.md](./DEPLOYMENT.md) | 🚀 Guide déploiement manuel production |

---

## 🛠️ Tech Stack

### Backend
- **Django 4.x** - Web framework
- **Django REST Framework** - API REST
- **PostgreSQL 15** - Database
- **Gunicorn** - WSGI server
- **Nginx** - Reverse proxy
- **Docker** - Containerization

### Frontend Web
- **Tailwind CSS** - Utility-first CSS
- **Alpine.js** - Lightweight JS framework
- **Leaflet** - Maps interactives
- **Three.js** - Animations 3D (desktop only)

### Mobile
- **Flutter 3.x** - Cross-platform framework
- **Riverpod** - State management
- **GoRouter** - Navigation
- **Dio** - HTTP client
- **Freezed** - Immutable models

### DevOps
- **Docker Compose** - Container orchestration
- **GitHub Actions** - CI/CD (optional)
- **Cron** - Scheduled tasks
- **Bash Scripts** - Automation

---

## 🏗️ Architecture

```
coucou_beaute/
├── backend/                    # Django Backend
│   ├── users/                  # Authentification, profils
│   ├── appointments/           # Réservations
│   ├── reviews/                # Avis clients
│   ├── subscriptions/          # Abonnements pros
│   ├── adminpanel/             # Dashboard admin
│   ├── front_web/              # Pages web publiques
│   ├── shared/                 # Templates, static files
│   │   ├── static/
│   │   │   ├── css/
│   │   │   │   ├── global.css
│   │   │   │   └── responsive-mobile.css  # 📱 Nouveau
│   │   │   └── js/
│   │   └── templates/
│   │       └── base.html       # Template de base
│   ├── coucou_beaute/          # Settings Django
│   └── manage.py
├── coucou_beaute_mobile/       # Flutter App
│   ├── lib/
│   │   ├── models/
│   │   ├── providers/
│   │   ├── screens/
│   │   ├── widgets/
│   │   └── main.dart
│   └── pubspec.yaml
├── docker-compose.yml          # Dev environment
├── docker-compose.prod.yml     # Production environment
├── nginx.conf                  # Nginx configuration
├── deploy.sh                   # 🚀 Script déploiement
├── deploy-cron.sh              # 🤖 Auto-déploiement
├── quick-setup.sh              # ⚡ Setup rapide
└── README.md                   # Ce fichier
```

---

## 🧪 Tests & Validation

### Backend
```bash
cd backend
python manage.py test
```

### Mobile
```bash
cd coucou_beaute_mobile
flutter test
```

### Responsive Mobile
Tester sur:
- ✅ iPhone SE (375×667)
- ✅ iPhone 12/13/14 (390×844)
- ✅ iPhone 14 Pro Max (430×932)
- ✅ Samsung Galaxy S21 (360×800)
- ✅ iPad Mini (768×1024)

---

## 🔒 Sécurité

- ✅ HTTPS/TLS (Let's Encrypt recommended)
- ✅ CSRF Protection
- ✅ CORS Configuration
- ✅ SQL Injection Prevention (Django ORM)
- ✅ XSS Protection (Django templates)
- ✅ Secure Headers (HSTS, X-Frame-Options, etc.)
- ✅ Environment Variables (secrets not in code)
- ✅ Docker Non-Root User

---

## 📊 Performances

### Web
- ✅ **Three.js disabled** sur mobile (économie CPU)
- ✅ **Gzip compression** (Nginx)
- ✅ **Static caching** (1 an)
- ✅ **Lazy loading** images
- ✅ **Minified CSS/JS**

### Backend
- ✅ **Database indexing** (PostgreSQL)
- ✅ **Query optimization** (Django ORM)
- ✅ **Connection pooling**
- ✅ **Gunicorn workers** (auto-scaling)

### Mobile
- ✅ **Image caching**
- ✅ **API response caching**
- ✅ **Lazy loading** lists
- ✅ **Optimized builds** (release mode)

---

## 🤝 Contribution

1. Fork le projet
2. Créer une branche feature (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. Ouvrir une Pull Request

---

## 📝 Changelog

### Version 2.0 (Octobre 2025)
- ✅ Responsive mobile 100% (iOS, Android compatible)
- ✅ Auto-déploiement cron-based
- ✅ HTTPS/SSL configuration
- ✅ Docker production optimizations
- ✅ Upload fichiers fixes (permissions, size limits)
- ✅ Documentation complète

### Version 1.0 (Initial)
- Backend Django REST
- Application mobile Flutter
- Infrastructure Docker
- Admin dashboard

---

## 📄 Licence

Ce projet est sous licence privée. Tous droits réservés © 2025 Coucou Beauté.

---

## 📞 Support

- 📧 Email: support@coucoubeaute.com
- 📱 Téléphone: +216 XX XXX XXX
- 🌐 Site: https://coucoubeaute.com

---

**Développé avec ❤️ par l'équipe Coucou Beauté**