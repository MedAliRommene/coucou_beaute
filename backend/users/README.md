# Users Application

## Description

Gestion des utilisateurs, clients et professionnels

## Structure

```
users/
├── models.py          # Modèles de données
├── views.py           # Vues et logique métier
├── urls.py            # Configuration des URLs
├── admin.py           # Interface d'administration
├── serializers.py     # Serializers DRF
├── templates/         # Templates HTML
├── static/            # Fichiers statiques
├── migrations/        # Migrations de base de données
├── tests/             # Tests unitaires
└── api/               # Endpoints API
```

## Modèles

- **User**: Description du modèle
- **Client**: Description du modèle
- **Professional**: Description du modèle

## Vues

- **Authentication**: Description de la vue
- **User management**: Description de la vue
- **Profile views**: Description de la vue

## Endpoints API

- `/api/auth/`: Description de l'endpoint
- `/api/users/`: Description de l'endpoint
- `/api/professionals/`: Description de l'endpoint

## Workflow

1. **Configuration**: Initialisation de l'application
2. **Données**: Gestion des modèles et migrations
3. **Logique**: Implémentation des vues et services
4. **Interface**: Templates et fichiers statiques
5. **API**: Endpoints REST pour l'intégration
6. **Tests**: Validation du fonctionnement
