# Appointments Application

## Description

Système de prise de rendez-vous

## Structure

```
appointments/
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

- **Appointment**: Description du modèle
- **TimeSlot**: Description du modèle
- **Service**: Description du modèle

## Vues

- **Booking**: Description de la vue
- **Scheduling**: Description de la vue
- **Calendar views**: Description de la vue

## Endpoints API

- `/api/appointments/`: Description de l'endpoint
- `/api/services/`: Description de l'endpoint
- `/api/timeslots/`: Description de l'endpoint

## Workflow

1. **Configuration**: Initialisation de l'application
2. **Données**: Gestion des modèles et migrations
3. **Logique**: Implémentation des vues et services
4. **Interface**: Templates et fichiers statiques
5. **API**: Endpoints REST pour l'intégration
6. **Tests**: Validation du fonctionnement
