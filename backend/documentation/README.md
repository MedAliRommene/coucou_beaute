# Coucou Beauté — Documentation Backend

Cette documentation décrit l'architecture, l'installation, la configuration et l'exploitation du backend Django du projet Coucou Beauté.

## 1) Aperçu
- Framework: Django 4.x + Django REST Framework (DRF)
- Authentification: Session (AdminPanel) + base prête pour JWT (SimpleJWT)
- Base de données: PostgreSQL
- Stockage statique/média: système de fichiers local (dev), S3 via `django-storages` (prod possible)
- Internationalisation: `LANGUAGE_CODE = 'fr'`

## 2) Structure du projet (backend)
```
backend/
├── adminpanel/                 # Application d'administration (UI, login, dashboard)
│   ├── templates/adminpanel/   # Templates HTML de l'UI admin
│   └── static/adminpanel/      # Assets spécifiques à l'admin
├── users/                      # Utilisateurs et profils (User, Client, Professional)
│   └── models.py               # Custom User (hérite d'AbstractUser)
├── appointments/               # Rendez-vous (modèles/urls à compléter)
├── reviews/                    # Avis (modèles/urls à compléter)
├── subscriptions/              # Abonnements (modèles/urls à compléter)
├── shared/                     # Templates / statics partagés (base.html, css/js globaux)
│   ├── templates/base.html
│   └── static/
├── coucou_beaute/              # Projet Django (settings/urls)
│   ├── settings.py
│   └── urls.py
├── documentation/              # Cette documentation
├── requirements/               # Dépendances par environnement
│   ├── base.txt
│   ├── development.txt
│   ├── production.txt
│   └── test.txt
├── media/                      # Fichiers utilisateurs (logo, images)
├── manage.py
└── Dockerfile
```

Important: les apps sont en « structure plate » (une app = un dossier directement dans `backend/`). Aucune app n’est sous `backend/apps/`.

## 3) Pré-requis
- Python ≥ 3.10
- PostgreSQL ≥ 13
- Outils: `pip`, `venv`

## 4) Installation locale
```bash
# 1. Créer un venv et l'activer
python -m venv .venv
. .venv/Scripts/activate  # Windows PowerShell/CMD

# 2. Installer les dépendances
pip install -r requirements/development.txt

# 3. Variables d'environnement (.env à la racine de backend/)
# Créez un fichier .env avec au minimum:
# DJANGO_SECRET_KEY=dev-secret
# DJANGO_DEBUG=True
# DJANGO_ALLOWED_HOSTS=*
# POSTGRES_DB=coucou_local
# POSTGRES_USER=postgres
# POSTGRES_PASSWORD=admin
# POSTGRES_HOST=localhost
# POSTGRES_PORT=5432

# 4. Migrations (obligatoire car User custom)
python manage.py makemigrations users
python manage.py migrate

# 5. Créer un superutilisateur
python manage.py createsuperuser

# 6. Lancer le serveur
python manage.py runserver
```

## 5) Configuration Django
Extraits clés de `coucou_beaute/settings.py`:
- Apps installées (structure plate): `users`, `appointments`, `reviews`, `subscriptions`, `adminpanel`
- Modèle utilisateur custom: `AUTH_USER_MODEL = 'users.User'`
- Auth redirects:
  - `LOGIN_URL = '/login/'`
  - `LOGIN_REDIRECT_URL = '/dashboard/'`
  - `LOGOUT_REDIRECT_URL = '/login/'`
- Templates:
  - `TEMPLATES.DIRS = [BASE_DIR / 'shared' / 'templates']` pour `shared/templates/base.html`
  - `APP_DIRS = True` pour charger `app/templates/app/...`
- Statics:
  - `STATICFILES_DIRS = [BASE_DIR / 'shared' / 'static']`
- Médias: `MEDIA_URL = '/media/'`, `MEDIA_ROOT = BASE_DIR / 'media'`

## 6) Routage
`coucou_beaute/urls.py` inclut :
- UI Admin: `path('', include('adminpanel.urls', namespace='adminpanel'))`
- Administration Django: `path('admin/', admin.site.urls)`
- API (provisoire): `path('api/', include('users.urls'))` — à remplacer par `core.api_urls` quand l’API sera centralisée.

`adminpanel/urls.py` expose:
- `/login/`, `/logout/`, `/dashboard/`, `/clients/`, `/pros/`, `/pros/pending/`, `/appointments/`, `/reviews/`, `/subscriptions/`, `/notifications/`, `/stats/`, `/settings/`

## 7) Authentification
- UI Admin: authentification par session (formulaire Django `AuthenticationForm`).
- Le login accepte email ou username (conversion email→username effectuée en vue).
- Redirections automatiques: après login vers `/dashboard/`, après logout vers `/login/`.
- Modèle `User` custom (hérite d’`AbstractUser`) dans `users/models.py`. L’email est unique.

## 8) Applications
### 8.1 Users
- Modèles: `User`, `Client`, `Professional`
- Admin: inscrits dans `users/admin.py`
- Endpoints API: à enrichir via `users/urls.py` + DRF

### 8.2 AdminPanel
- Templates modernes sous `adminpanel/templates/adminpanel/`
- `base.html` partagé via `shared/templates/base.html`
- Navigation latérale, KPI, charts (Chart.js), Tailwind, Lucide Icons

### 8.3 Appointments / Reviews / Subscriptions
- Squelettes présents (modèles/urls à compléter)

## 9) Templates & Statics
- Modèle par app: `app/templates/app/*.html`
- Global partagé: `shared/templates/base.html`
- Statics globaux: `shared/static/{css,js,images}` + statics par app `app/static/app/...`

## 10) API & DRF
- DRF activé. Classe d’auth par défaut: SimpleJWT (côté API) déjà configurée dans `REST_FRAMEWORK`.
- Ajoutez vos ViewSets/Serializers/routers au fur et à mesure (ex.: `users/api.py`, `users/serializers.py`).

## 11) Tests
- Pytest prêt (voir `pytest.ini`). Exemple:
```bash
pytest -q
```

## 12) Déploiement (aperçu)
- Prod Python: Gunicorn (`requirements/production.txt`) + Whitenoise pour statics ou S3 via `django-storages`.
- Variables sensibles via `.env`.
- Docker possible (Dockerfile présent, docker-compose à adapter si besoin).

## 13) Sécurité & bonnes pratiques
- Toujours définir `DJANGO_SECRET_KEY` unique en prod
- `DEBUG=False` et `ALLOWED_HOSTS` correctement configurés
- HTTPS (proxy/Nginx), CSRF/CORS (via `corsheaders`)
- Validation des professionnels et vérification des documents côté business

## 14) Internationalisation
- Paramètre par défaut FR. Activer `LANGUAGES` et middlewares si besoin d’i18n avancée (FR/AR/EN).

## 15) Résolution de problèmes (FAQ)
- ModuleNotFoundError (ex: `core`): vérifier la structure plate (dossiers directement dans `backend/`) et `INSTALLED_APPS`.
- `AUTH_USER_MODEL ... not been installed`: exécuter `makemigrations users && migrate` après avoir ajouté le modèle `User`.
- Connexion DB PostgreSQL en local: `HOST=localhost` (et non `db` qui est réservé au Docker compose).
- Le logo/medias ne s’affichent pas: vérifier `MEDIA_URL`, `MEDIA_ROOT` et l’URL de développement `urlpatterns += static(...)` en DEBUG.
- Statics non trouvés: vérifier `STATICFILES_DIRS` et emplacements `app/static/app/...`.

## 16) Roadmap
- Centraliser l’API sous `core/` (endpoints publics et admin)
- Recherche et filtrage avancés (services/professionnels/clients)
- Notifications push (FCM)
- Modules paiement (Stripe) et facturation
- Permissions fines (groupes/roles)

---
Ancienne documentation (pré-existante) ci-dessous :

## 🎯 **Vue d'ensemble du Projet**

**Coucou Beauté** est une plateforme de prise de rendez-vous beauté développée avec Django REST Framework. Le projet suit une architecture modulaire avec des applications spécialisées pour chaque domaine métier.

## 🏗️ **Architecture du Projet**

```
backend/
├── coucou_beaute/          # Configuration principale Django
├── core/                   # Fonctionnalités centrales et API
├── users/                  # Gestion des utilisateurs et authentification
├── appointments/           # Gestion des rendez-vous
├── reviews/               # Système d'avis et évaluations
├── subscriptions/         # Gestion des abonnements
├── adminpanel/            # Interface d'administration
├── documentation/         # Documentation complète du projet
└── media/                 # Fichiers média (logos, images)
```

## 🔧 **Technologies Utilisées**

- **Framework**: Django 4.x + Django REST Framework
- **Base de données**: PostgreSQL
- **Authentification**: JWT (djangorestframework-simplejwt)
- **Documentation API**: drf-spectacular
- **Tests**: pytest-django
- **Déploiement**: Docker + Gunicorn

## 📱 **Applications Frontend**

- **Application Mobile**: Flutter 3.x
- **Dashboard Admin**: Interface web moderne avec Tailwind CSS
- **API REST**: Endpoints pour l'application mobile

## 🚀 **Installation et Configuration**

### Prérequis
- Python 3.8+
- PostgreSQL 12+
- Node.js (pour les assets frontend)

### Installation
```bash
# Cloner le projet
git clone <repository-url>
cd coucou-beaute/backend

# Créer l'environnement virtuel
python -m venv venv
source venv/bin/activate  # Linux/Mac
# ou
venv\Scripts\activate     # Windows

# Installer les dépendances
pip install -r requirements.txt

# Configuration de la base de données
cp env.example .env
# Éditer .env avec vos paramètres

# Migrations
python manage.py makemigrations
python manage.py migrate

# Créer un superuser
python manage.py createsuperuser

# Lancer le serveur
python manage.py runserver
```

## 📊 **Structure de la Base de Données**

### Modèles Principaux
- **User**: Utilisateurs (clients et professionnels)
- **Professional**: Profils des professionnels
- **Service**: Services proposés
- **Appointment**: Rendez-vous
- **Review**: Avis clients
- **Subscription**: Abonnements

## 🔐 **Système d'Authentification**

- **JWT Tokens** pour l'API mobile
- **Session Django** pour l'interface admin
- **Permissions** basées sur les rôles utilisateur
- **Validation** des professionnels par les administrateurs

## 📈 **Fonctionnalités Principales**

### Pour les Clients
- Inscription et connexion
- Recherche de professionnels
- Prise de rendez-vous
- Évaluation des services
- Gestion du profil

### Pour les Professionnels
- Inscription et validation
- Gestion du calendrier
- Gestion des services
- Suivi des clients

### Pour les Administrateurs
- Validation des professionnels
- Tableau de bord analytique
- Gestion des utilisateurs
- Modération des avis

## 🧪 **Tests**

```bash
# Lancer tous les tests
pytest

# Tests avec couverture
pytest --cov=.

# Tests d'une app spécifique
pytest apps/users/
```

## 📚 **Documentation des Applications**

Chaque application contient sa propre documentation détaillée :
- [Core Documentation](core/README.md)
- [Users Documentation](users/README.md)
- [Appointments Documentation](appointments/README.md)
- [Reviews Documentation](reviews/README.md)
- [Subscriptions Documentation](subscriptions/README.md)
- [Admin Panel Documentation](adminpanel/README.md)

## 🔄 **Workflow de Développement**

1. **Développement local** avec environnement virtuel
2. **Tests** automatiques avant commit
3. **Code review** et validation
4. **Déploiement** via Docker
5. **Monitoring** et maintenance

## 📝 **Conventions de Code**

- **PEP 8** pour le style Python
- **Docstrings** pour toutes les fonctions
- **Type hints** pour les paramètres
- **Tests unitaires** pour chaque fonctionnalité
- **Messages de commit** en français

## 🤝 **Contribution**

1. Fork du projet
2. Création d'une branche feature
3. Développement et tests
4. Pull Request avec description détaillée
5. Review et merge

## 📞 **Support**

- **Documentation**: Ce dossier
- **Issues**: GitHub Issues
- **Email**: support@coucoubeaute.com

---

*Dernière mise à jour: Janvier 2025*
*Version: 1.0.0*
