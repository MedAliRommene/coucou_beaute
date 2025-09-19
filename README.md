# Coucou Beauté – Monorepo (Flutter + Django)

Ce dépôt contient:
- `backend/` API Django REST Framework (JWT, PostgreSQL, stockage fichiers, notifications FCM)
- `flutter_app/` application mobile Flutter (Clean Architecture, Riverpod, GoRouter, i18n FR/AR/EN)
- `docker-compose.yml` pour lancer Postgres + backend Django (Redis optionnel)

## Démarrage rapide (Docker)

1. Copier `env.example` en `.env` et ajuster les variables.
2. Lancer:
```bash
docker-compose up --build
```
3. API disponible sur `http://localhost:8000/api/`.

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

## Notes

- Authentification JWT via `djangorestframework-simplejwt`
- Notifications push via FCM (env `FCM_SERVER_KEY`)
- Stockage fichiers: `django-storages` (S3) ou local en dev (`MEDIA_ROOT`)
- Internationalisation mobile: FR/AR/EN, support RTL
- (test)