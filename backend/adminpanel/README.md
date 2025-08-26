# Adminpanel Application

## Description

Interface d'administration moderne

## Structure

```
adminpanel/
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

- **AdminUser**: Description du modèle
- **Dashboard**: Description du modèle
- **Analytics**: Description du modèle

## Vues

- **Login**: Description de la vue
- **Dashboard**: Description de la vue
- **User management**: Description de la vue
- **Analytics**: Description de la vue

## Endpoints API

- `/login/`: Description de l'endpoint
- `/dashboard/`: Description de l'endpoint
- `/users/`: Description de l'endpoint
- `/analytics/`: Description de l'endpoint

## Workflow

1. **Configuration**: Initialisation de l'application
2. **Données**: Gestion des modèles et migrations
3. **Logique**: Implémentation des vues et services
4. **Interface**: Templates et fichiers statiques
5. **API**: Endpoints REST pour l'intégration
6. **Tests**: Validation du fonctionnement
