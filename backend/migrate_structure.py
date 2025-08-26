#!/usr/bin/env python3
"""
Script de Migration de la Structure Backend
Coucou Beauté - Restructuration Modulaire

Ce script automatise la migration vers une architecture modulaire
avec des apps organisées et une documentation complète.
"""

import os
import sys
import shutil
from pathlib import Path
import json

class StructureMigrator:
    def __init__(self, base_dir):
        self.base_dir = Path(base_dir)
        self.backend_dir = self.base_dir / "backend"
        self.apps_dir = self.backend_dir / "apps"
        self.shared_dir = self.backend_dir / "shared"
        self.docs_dir = self.backend_dir / "documentation"
        self.requirements_dir = self.backend_dir / "requirements"
        
    def run_migration(self):
        """Exécute la migration complète"""
        print("🚀 Début de la migration de l'architecture backend...")
        
        try:
            # 1. Création de la nouvelle structure
            self.create_directory_structure()
            
            # 2. Migration des apps existantes
            self.migrate_existing_apps()
            
            # 3. Migration des templates et static
            self.migrate_templates_and_static()
            
            # 4. Création des composants partagés
            self.create_shared_components()
            
            # 5. Organisation des requirements
            self.organize_requirements()
            
            # 6. Génération de la documentation
            self.generate_documentation()
            
            # 7. Création du guide de migration
            self.create_migration_guide()
            
            print("✅ Migration terminée avec succès!")
            print(f"📁 Nouvelle structure créée dans: {self.apps_dir}")
            print(f"📚 Documentation disponible dans: {self.docs_dir}")
            
        except Exception as e:
            print(f"❌ Erreur lors de la migration: {e}")
            return False
        
        return True
    
    def create_directory_structure(self):
        """Crée la nouvelle structure de répertoires"""
        print("📁 Création de la structure des répertoires...")
        
        # Répertoires principaux
        directories = [
            self.apps_dir,
            self.shared_dir,
            self.docs_dir,
            self.requirements_dir,
        ]
        
        # Répertoires pour chaque app
        app_names = ['core', 'users', 'appointments', 'reviews', 'subscriptions', 'adminpanel']
        for app_name in app_names:
            app_dir = self.apps_dir / app_name
            directories.extend([
                app_dir,
                app_dir / 'templates' / app_name,
                app_dir / 'static' / app_name,
                app_dir / 'migrations',
                app_dir / 'tests',
                app_dir / 'api',
            ])
        
        # Création des répertoires
        for directory in directories:
            directory.mkdir(parents=True, exist_ok=True)
            print(f"  ✅ Créé: {directory}")
    
    def migrate_existing_apps(self):
        """Migre les apps existantes vers la nouvelle structure"""
        print("🔄 Migration des apps existantes...")
        
        # Apps à migrer
        apps_to_migrate = ['adminpanel', 'core']
        
        for app_name in apps_to_migrate:
            source_dir = self.backend_dir / app_name
            target_dir = self.apps_dir / app_name
            
            if source_dir.exists():
                print(f"  📦 Migration de {app_name}...")
                
                # Copie de l'app
                if target_dir.exists():
                    shutil.rmtree(target_dir)
                shutil.copytree(source_dir, target_dir)
                
                # Suppression de l'original
                shutil.rmtree(source_dir)
                
                print(f"    ✅ {app_name} migré vers {target_dir}")
            else:
                print(f"    ⚠️ App {app_name} non trouvée, création d'une structure vide")
                self.create_empty_app_structure(app_name)
    
    def create_empty_app_structure(self, app_name):
        """Crée une structure vide pour une nouvelle app"""
        app_dir = self.apps_dir / app_name
        
        # Fichiers de base
        files = {
            '__init__.py': '',
            'apps.py': f"""from django.apps import AppConfig

class {app_name.capitalize()}Config(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'apps.{app_name}'
""",
            'models.py': '# Modèles pour l\'app {}\n'.format(app_name),
            'views.py': '# Vues pour l\'app {}\n'.format(app_name),
            'urls.py': f"""from django.urls import path
from . import views

app_name = '{app_name}'

urlpatterns = [
    # URLs pour {app_name}
]
""",
            'admin.py': f"""from django.contrib import admin
# Register your models here.
""",
        }
        
        for filename, content in files.items():
            file_path = app_dir / filename
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
    
    def migrate_templates_and_static(self):
        """Migre les templates et fichiers static"""
        print("🎨 Migration des templates et fichiers static...")
        
        # Migration des templates centraux (s'ils existent)
        central_templates = self.backend_dir / 'templates'
        if central_templates.exists():
            print("  📝 Migration des templates centraux...")
            for item in central_templates.iterdir():
                if item.is_dir():
                    app_name = item.name
                    target_dir = self.apps_dir / app_name / 'templates' / app_name
                    if target_dir.exists():
                        # Fusion des templates
                        for template_file in item.rglob('*.html'):
                            target_file = target_dir / template_file.name
                            shutil.copy2(template_file, target_file)
                            print(f"    ✅ Template migré: {template_file.name}")
                    else:
                        # Copie complète
                        shutil.copytree(item, target_dir)
                        print(f"    ✅ Templates migrés pour {app_name}")
            
            # Suppression des templates centraux
            shutil.rmtree(central_templates)
            print("    🗑️ Templates centraux supprimés")
        
        # Migration des fichiers static centraux
        central_static = self.backend_dir / 'static'
        if central_static.exists():
            print("  🎨 Migration des fichiers static centraux...")
            for item in central_static.iterdir():
                if item.is_dir():
                    app_name = item.name
                    target_dir = self.apps_dir / app_name / 'static' / app_name
                    if target_dir.exists():
                        # Fusion des fichiers static
                        for static_file in item.rglob('*'):
                            if static_file.is_file():
                                target_file = target_dir / static_file.name
                                shutil.copy2(static_file, target_file)
                    else:
                        # Copie complète
                        shutil.copytree(item, target_dir)
            
            # Suppression des fichiers static centraux
            shutil.rmtree(central_static)
            print("    🗑️ Fichiers static centraux supprimés")
    
    def create_shared_components(self):
        """Crée les composants partagés"""
        print("🔧 Création des composants partagés...")
        
        # Base template partagé
        base_template = self.shared_dir / 'templates' / 'base.html'
        base_template.parent.mkdir(parents=True, exist_ok=True)
        
        base_content = """<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}Coucou Beauté{% endblock %}</title>
    {% block extra_head %}{% endblock %}
</head>
<body>
    {% block content %}{% endblock %}
    {% block extra_js %}{% endblock %}
</body>
</html>"""
        
        with open(base_template, 'w', encoding='utf-8') as f:
            f.write(base_content)
        
        print("  ✅ Template de base partagé créé")
    
    def organize_requirements(self):
        """Organise les fichiers requirements par environnement"""
        print("📦 Organisation des requirements...")
        
        # Requirements de base
        base_requirements = """# Dependencies de base - Coucou Beaute
# Ces dependencies sont requises pour tous les environnements

Django>=4.2.0,<5.0.0
djangorestframework>=3.14.0,<4.0.0
djangorestframework-simplejwt>=5.2.0,<6.0.0
psycopg2-binary>=2.9.0,<3.0.0
django-storages>=1.13.0,<2.0.0
boto3>=1.26.0,<2.0.0
Pillow>=9.5.0,<10.0.0
python-dotenv>=1.0.0,<2.0.0
django-filter>=23.0,<24.0
drf-spectacular>=0.26.0,<1.0.0
"""
        
        # Requirements de développement
        dev_requirements = """# Requirements de développement
-r base.txt

# Outils de développement
django-debug-toolbar>=4.0.0,<5.0.0
django-extensions>=3.2.0,<4.0.0
ipython>=8.0.0,<9.0.0
"""
        
        # Requirements de test
        test_requirements = """# Requirements de test
-r base.txt

# Outils de test
pytest>=7.0.0,<8.0.0
pytest-django>=4.5.0,<5.0.0
pytest-cov>=4.0.0,<5.0.0
factory-boy>=3.2.0,<4.0.0
"""
        
        # Requirements de production
        prod_requirements = """# Requirements de production
-r base.txt

# Serveur de production
gunicorn>=20.1.0,<21.0.0
whitenoise>=6.5.0,<7.0.0

# Sécurité
django-cors-headers>=4.0.0,<5.0.0
"""
        
        # Écriture des fichiers
        requirements_files = {
            'base.txt': base_requirements,
            'development.txt': dev_requirements,
            'test.txt': test_requirements,
            'production.txt': prod_requirements
        }
        
        for filename, content in requirements_files.items():
            file_path = self.requirements_dir / filename
            with open(file_path, 'w', encoding='utf-8') as f:
                f.write(content)
            print(f"  ✅ {filename} créé")
        
        # Mise à jour du requirements.txt principal
        main_requirements = self.backend_dir / 'requirements.txt'
        if main_requirements.exists():
            main_requirements.unlink()
        
        # Création d'un requirements.txt principal qui pointe vers base.txt
        with open(main_requirements, 'w', encoding='utf-8') as f:
            f.write("-r requirements/base.txt\n")
        
        print("  ✅ requirements.txt principal mis à jour")
    
    def generate_documentation(self):
        """Génère la documentation pour chaque app"""
        print("📚 Génération de la documentation...")
        
        # Documentation principale
        main_readme = self.docs_dir / 'README.md'
        main_content = """# Coucou Beauté - Backend Documentation

## Vue d'ensemble

Ce projet utilise une architecture modulaire Django avec des applications organisées dans le dossier `apps/`.

## Structure du projet

```
backend/
├── apps/                    # Applications Django
│   ├── core/               # Fonctionnalités principales
│   ├── users/              # Gestion des utilisateurs
│   ├── appointments/        # Gestion des rendez-vous
│   ├── reviews/            # Système d'avis
│   ├── subscriptions/      # Gestion des abonnements
│   └── adminpanel/         # Interface d'administration
├── shared/                 # Composants partagés
├── requirements/           # Dépendances par environnement
└── documentation/          # Documentation du projet
```

## Installation

1. Créer un environnement virtuel Python
2. Installer les dépendances: `pip install -r requirements/development.txt`
3. Configurer les variables d'environnement
4. Exécuter les migrations: `python manage.py migrate`
5. Créer un superutilisateur: `python manage.py createsuperuser`
6. Lancer le serveur: `python manage.py runserver`

## Applications disponibles

- **Core**: API de base et configuration
- **Users**: Authentification et gestion des utilisateurs
- **Appointments**: Système de prise de rendez-vous
- **Reviews**: Système d'avis et évaluations
- **Subscriptions**: Gestion des abonnements
- **AdminPanel**: Interface d'administration

## API

L'API REST est accessible via `/api/` et utilise JWT pour l'authentification.

## Tests

Exécuter les tests: `pytest`

## Déploiement

Utiliser `requirements/production.txt` pour le déploiement en production.
"""
        
        with open(main_readme, 'w', encoding='utf-8') as f:
            f.write(main_content)
        
        print("  ✅ README principal créé")
        
        # Documentation pour chaque app
        app_docs = {
            'core': {
                'title': 'Core Application',
                'description': 'Application principale contenant les fonctionnalités de base, la configuration et l\'API principale.',
                'models': ['Configuration', 'Settings'],
                'views': ['API endpoints', 'Configuration views'],
                'endpoints': ['/api/config/', '/api/health/']
            },
            'users': {
                'title': 'Users Application',
                'description': 'Gestion des utilisateurs, authentification JWT, et profils utilisateur.',
                'models': ['User', 'Client', 'Professional'],
                'views': ['Authentication', 'User management', 'Profile views'],
                'endpoints': ['/api/auth/', '/api/users/', '/api/professionals/']
            },
            'appointments': {
                'title': 'Appointments Application',
                'description': 'Système de prise de rendez-vous avec gestion des créneaux et notifications.',
                'models': ['Appointment', 'TimeSlot', 'Service'],
                'views': ['Booking', 'Scheduling', 'Calendar views'],
                'endpoints': ['/api/appointments/', '/api/services/', '/api/timeslots/']
            },
            'reviews': {
                'title': 'Reviews Application',
                'description': 'Système d\'avis et évaluations pour les professionnels et services.',
                'models': ['Review', 'Rating', 'Comment'],
                'views': ['Review creation', 'Rating display', 'Moderation'],
                'endpoints': ['/api/reviews/', '/api/ratings/']
            },
            'subscriptions': {
                'title': 'Subscriptions Application',
                'description': 'Gestion des abonnements et plans de fidélité.',
                'models': ['Subscription', 'Plan', 'Payment'],
                'views': ['Subscription management', 'Plan selection', 'Payment processing'],
                'endpoints': ['/api/subscriptions/', '/api/plans/', '/api/payments/']
            },
            'adminpanel': {
                'title': 'AdminPanel Application',
                'description': 'Interface d\'administration moderne avec tableau de bord analytique.',
                'models': ['AdminUser', 'Dashboard', 'Analytics'],
                'views': ['Login', 'Dashboard', 'User management', 'Analytics'],
                'endpoints': ['/login/', '/dashboard/', '/users/', '/analytics/']
            }
        }
        
        for app_name, app_info in app_docs.items():
            app_doc_path = self.apps_dir / app_name / 'README.md'
            app_content = f"""# {app_info['title']}

## Description

{app_info['description']}

## Structure

```
{app_name}/
├── models.py          # Modèles de données
├── views.py           # Vues et logique métier
├── urls.py            # Configuration des URLs
├── admin.py           # Interface d'administration
├── templates/         # Templates HTML
├── static/            # Fichiers statiques
├── migrations/        # Migrations de base de données
├── tests/             # Tests unitaires
└── api/               # Endpoints API
```

## Modèles

{chr(10).join([f"- **{model}**: Description du modèle" for model in app_info['models']])}

## Vues

{chr(10).join([f"- **{view}**: Description de la vue" for view in app_info['views']])}

## Endpoints API

{chr(10).join([f"- `{endpoint}`: Description de l'endpoint" for endpoint in app_info['endpoints']])}

## Workflow

1. **Configuration**: Initialisation de l'application
2. **Données**: Gestion des modèles et migrations
3. **Logique**: Implémentation des vues et services
4. **Interface**: Templates et fichiers statiques
5. **API**: Endpoints REST pour l'intégration
6. **Tests**: Validation du fonctionnement

## Utilisation

Cette application est utilisée par le système principal et peut être étendue selon les besoins spécifiques.
"""
            
            with open(app_doc_path, 'w', encoding='utf-8') as f:
                f.write(app_content)
            
            print(f"  ✅ Documentation créée pour {app_name}")
    
    def create_migration_guide(self):
        """Crée un guide de migration"""
        print("📋 Création du guide de migration...")
        
        guide_content = """# Guide de Migration - Architecture Modulaire

## Avant vs Après

### Structure Ancienne
```
backend/
├── adminpanel/
├── core/
├── templates/
├── static/
└── requirements.txt
```

### Structure Nouvelle
```
backend/
├── apps/
│   ├── adminpanel/
│   ├── core/
│   ├── users/
│   ├── appointments/
│   ├── reviews/
│   └── subscriptions/
├── shared/
├── requirements/
│   ├── base.txt
│   ├── development.txt
│   ├── test.txt
│   └── production.txt
└── documentation/
```

## Étapes de Migration

### 1. Préparation
- [ ] Sauvegarder le projet
- [ ] Vérifier que tous les tests passent
- [ ] Créer une branche de migration

### 2. Exécution du Script
```bash
cd backend
python migrate_structure.py
```

### 3. Vérifications Post-Migration
- [ ] Vérifier que la structure est correcte
- [ ] Tester que l'application démarre
- [ ] Vérifier que les URLs fonctionnent
- [ ] Tester les fonctionnalités principales

### 4. Mise à Jour des Imports
- [ ] Mettre à jour les imports dans `settings.py`
- [ ] Vérifier les imports dans les apps
- [ ] Mettre à jour les références de templates

### 5. Tests et Validation
- [ ] Exécuter les tests unitaires
- [ ] Tester l'interface d'administration
- [ ] Vérifier l'API REST
- [ ] Tester les fonctionnalités utilisateur

## Configuration Django

### settings.py
```python
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    
    # Apps locales
    'apps.core',
    'apps.users',
    'apps.appointments',
    'apps.reviews',
    'apps.subscriptions',
    'apps.adminpanel',
]

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [
            BASE_DIR / 'shared' / 'templates',
        ],
        'APP_DIRS': True,
        # ...
    },
]

STATICFILES_DIRS = [
    BASE_DIR / 'shared' / 'static',
]
```

## Résolution des Problèmes

### Problème: Imports cassés
**Solution**: Mettre à jour les imports pour utiliser le nouveau chemin `apps.{app_name}`

### Problème: Templates non trouvés
**Solution**: Vérifier que les templates sont dans `apps/{app_name}/templates/{app_name}/`

### Problème: Fichiers static non trouvés
**Solution**: Vérifier que les fichiers sont dans `apps/{app_name}/static/{app_name}/`

## Rollback

En cas de problème, restaurer la sauvegarde et annuler la migration.

## Support

Consulter la documentation dans `documentation/` pour plus de détails.
"""
        
        guide_path = self.backend_dir / 'MIGRATION_GUIDE.md'
        with open(guide_path, 'w', encoding='utf-8') as f:
            f.write(guide_content)
        
        print("  ✅ Guide de migration créé")

def main():
    """Fonction principale"""
    if len(sys.argv) > 1:
        base_dir = sys.argv[1]
    else:
        base_dir = "."
    
    migrator = StructureMigrator(base_dir)
    migrator.run_migration()

if __name__ == "__main__":
    main()
