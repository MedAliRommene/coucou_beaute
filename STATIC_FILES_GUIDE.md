# 📁 Guide des Fichiers Statiques - Coucou Beauté

## 🎯 Comprendre les Fichiers Statiques Django

### 📂 Structure des Dossiers

```
coucou_beaute/
├── backend/
│   ├── static/                    # ❌ IGNORER (collectstatic output root)
│   ├── staticfiles/               # ❌ IGNORER (collectstatic output)
│   ├── media/                     # ❌ IGNORER (user uploads)
│   │
│   ├── adminpanel/
│   │   └── static/adminpanel/     # ✅ GARDER (source CSS/JS)
│   │       └── css/
│   │           └── admin-mobile.css
│   │
│   ├── front_web/
│   │   └── static/front_web/      # ✅ GARDER (source CSS/JS)
│   │       ├── css/
│   │       └── js/
│   │
│   └── shared/
│       └── static/                # ✅ GARDER (source CSS/JS global)
│           ├── css/
│           │   ├── global.css
│           │   ├── responsive-mobile.css
│           │   └── dashboard-mobile.css
│           └── js/
│               └── global.js
```

---

## ✅ Règles .gitignore

### ❌ À TOUJOURS Ignorer

1. **`media/`** - Fichiers uploadés par les utilisateurs
   - Photos de profil
   - Documents
   - Images de services
   - **Raison**: Trop volumineux, générés par les utilisateurs

2. **`staticfiles/`** - Sortie de `collectstatic`
   - Tous les fichiers static collectés
   - **Raison**: Généré automatiquement par Django

3. **`backend/static/`** (root) - Dossier de collecte
   - **Raison**: C'est `STATIC_ROOT`, géré par collectstatic

### ✅ À GARDER dans Git

1. **`backend/*/static/`** - Sources CSS/JS des apps
   - `adminpanel/static/`
   - `front_web/static/`
   - `users/static/`
   - etc.
   - **Raison**: C'est notre **code source**!

2. **`backend/shared/static/`** - CSS/JS globaux
   - **Raison**: Fichiers partagés entre apps

---

## 🔧 Configuration .gitignore Correcte

```gitignore
# Media files (user uploads) - TOUJOURS ignorer
media/

# Staticfiles collectés - TOUJOURS ignorer
staticfiles/
backend/staticfiles/

# Static files - Ignorer SEULEMENT les fichiers collectés/générés
/static/
backend/static/

# EXCEPTION: Garder les sources static des apps Django
!backend/*/static/
!backend/shared/static/
```

---

## 🚀 Commandes Django Static Files

### En Développement

```bash
# Pas besoin de collectstatic
# Django sert les fichiers directement depuis chaque app
python manage.py runserver
```

### En Production

```bash
# Collecter tous les fichiers static
python manage.py collectstatic --noinput

# Résultat:
# backend/adminpanel/static/adminpanel/css/admin-mobile.css
#   → backend/static/adminpanel/css/admin-mobile.css
#
# backend/shared/static/css/global.css
#   → backend/static/css/global.css
```

---

## 📊 Settings Django

### `settings.py`

```python
# URL pour accéder aux fichiers static
STATIC_URL = '/static/'

# Dossier où collectstatic va copier les fichiers
STATIC_ROOT = BASE_DIR / 'static'

# Dossiers additionnels à inclure (en plus des app/static/)
STATICFILES_DIRS = [
    BASE_DIR / 'shared' / 'static',
]

# Finders pour découvrir les fichiers
STATICFILES_FINDERS = [
    'django.contrib.staticfiles.finders.FileSystemFinder',  # STATICFILES_DIRS
    'django.contrib.staticfiles.finders.AppDirectoriesFinder',  # app/static/
]
```

---

## 🐳 Docker & Production

### Volume Mapping

```yaml
volumes:
  - static_data:/app/static      # STATIC_ROOT
  - media_data:/app/media        # MEDIA_ROOT
```

### Nginx Configuration

```nginx
location /static/ {
    alias /var/www/static/;      # Volume static_data
}

location /media/ {
    alias /var/www/media/;       # Volume media_data
}
```

---

## ⚠️ Erreurs Communes

### ❌ Erreur: "Static file not found"

**Cause**: Fichier CSS/JS ignoré par `.gitignore`

**Solution**: Vérifier que le dossier source n'est pas ignoré:
```bash
git check-ignore backend/adminpanel/static/adminpanel/css/admin-mobile.css
# Si retourne un chemin → fichier ignoré!
```

### ❌ Erreur: "Repository too large"

**Cause**: `media/` ou `staticfiles/` commité par erreur

**Solution**:
```bash
# Supprimer du tracking (mais garder localement)
git rm -r --cached media/
git rm -r --cached staticfiles/
git commit -m "Remove media and staticfiles from git"
```

### ❌ Erreur: Fichiers CSS/JS manquants en production

**Cause**: Pas de `collectstatic` exécuté

**Solution**:
```bash
docker exec coucou_web python manage.py collectstatic --noinput
```

---

## 📝 Workflow de Développement

### 1. Créer un nouveau CSS/JS

```bash
# Créer dans le dossier app/static/
touch backend/adminpanel/static/adminpanel/css/new-feature.css
```

### 2. Référencer dans le template

```html
{% load static %}
<link rel="stylesheet" href="{% static 'adminpanel/css/new-feature.css' %}">
```

### 3. Commit vers Git

```bash
git add backend/adminpanel/static/adminpanel/css/new-feature.css
git commit -m "feat: add new-feature.css"
git push
```

### 4. Déployer en Production

```bash
# Sur le serveur
./deploy.sh

# Le script va:
# 1. git pull (récupère new-feature.css)
# 2. docker build (copie dans l'image)
# 3. collectstatic (copie vers STATIC_ROOT)
# 4. nginx sert depuis /static/
```

---

## 🎯 Résumé Best Practices

| Élément | Git | Production | Raison |
|---------|-----|------------|--------|
| `app/static/` (source) | ✅ OUI | ✅ Inclus | Code source |
| `shared/static/` (source) | ✅ OUI | ✅ Inclus | Code source |
| `backend/static/` (STATIC_ROOT) | ❌ NON | ✅ Généré | Sortie collectstatic |
| `staticfiles/` | ❌ NON | ✅ Généré | Sortie collectstatic |
| `media/` | ❌ NON | ✅ Volume | Uploads utilisateurs |

---

## 🔍 Vérification

### Vérifier ce qui est tracké

```bash
# Lister les fichiers static trackés
git ls-files | grep static

# Devrait montrer:
# backend/adminpanel/static/adminpanel/css/admin-mobile.css
# backend/shared/static/css/global.css
# backend/shared/static/css/responsive-mobile.css
# backend/shared/static/css/dashboard-mobile.css
# backend/shared/static/js/global.js
```

### Vérifier ce qui est ignoré

```bash
# Ne devrait PAS être tracké:
git check-ignore backend/static/
git check-ignore backend/staticfiles/
git check-ignore media/
```

---

## 📚 Références

- [Django Static Files Documentation](https://docs.djangoproject.com/en/4.2/howto/static-files/)
- [Django collectstatic](https://docs.djangoproject.com/en/4.2/ref/contrib/staticfiles/#collectstatic)
- [Best Practices for Static Files](https://docs.djangoproject.com/en/4.2/howto/static-files/deployment/)

---

**Dernière mise à jour**: Octobre 2025  
**Projet**: Coucou Beauté  
**Status**: ✅ Configuration Optimale

