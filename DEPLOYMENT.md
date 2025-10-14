# 🚀 Guide de Déploiement - Coucou Beauté

## 📋 Prérequis

- Docker et Docker Compose installés
- Git configuré
- Accès SSH au serveur

## 🔧 Configuration Initiale

### 1. **Première installation sur le serveur :**

```bash
# Cloner le repository
git clone <votre-repo-url>
cd coucou_beaute

# Configurer l'environnement de production
cp backend/env.example backend/.env
nano backend/.env  # Configurer vos valeurs
```

### 2. **Configuration du fichier .env :**

```bash
# Exemple de configuration pour la production
DJANGO_DEBUG=False
DJANGO_SECRET_KEY=votre-clé-secrète-générée
DJANGO_ALLOWED_HOSTS=votre-domaine.com,votre-ip,localhost

# Base de données
POSTGRES_DB=coucou_prod
POSTGRES_USER=coucou
POSTGRES_PASSWORD=votre-mot-de-passe-secure
POSTGRES_HOST=db
POSTGRES_PORT=5432

# Sécurité
CSRF_TRUSTED_ORIGINS=https://votre-domaine.com,http://votre-ip
DJANGO_CORS_ORIGINS=https://votre-domaine.com
CSRF_COOKIE_SECURE=True  # Pour HTTPS
SESSION_COOKIE_SECURE=True  # Pour HTTPS

# Email
EMAIL_HOST_USER=votre-email@gmail.com
EMAIL_HOST_PASSWORD=votre-mot-de-passe-email
```

## 🚀 Déploiement

### **Méthode 1 : Script automatique (Recommandé)**

```bash
# Rendre le script exécutable
chmod +x deploy.sh

# Lancer le déploiement
./deploy-simple.sh
```

### **Méthode 2 : Manuel**

```bash
# 1. Mise à jour du code
git pull origin main

# 2. Redémarrage des services
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

# 3. Vérification
docker compose -f docker-compose.prod.yml logs
```

## 🔍 Vérification

### **Tests de connectivité :**

```bash
# Test local
curl http://localhost:80

# Test externe
curl http://votre-ip:80
```

### **Logs des services :**

```bash
# Tous les services
docker compose -f docker-compose.prod.yml logs

# Service spécifique
docker compose -f docker-compose.prod.yml logs web
docker compose -f docker-compose.prod.yml logs db
```

## 🛠️ Maintenance

### **Créer un superutilisateur :**

```bash
docker compose -f docker-compose.prod.yml exec web python manage.py createsuperuser
```

### **Migrations de base de données :**

```bash
docker compose -f docker-compose.prod.yml exec web python manage.py migrate
```

### **Collecte des fichiers statiques :**

```bash
docker compose -f docker-compose.prod.yml exec web python manage.py collectstatic --noinput
```

## 🔒 Sécurité

### **Variables d'environnement sensibles :**

- ✅ **À faire** : Configurer dans `.env` (non versionné)
- ❌ **À éviter** : Mettre des secrets dans le code

### **Fichiers à ne jamais commiter :**

- `.env`
- `env.local`
- `env.prod`
- `*.backup`

## 🆘 Dépannage

### **Problème de connexion :**

1. Vérifier les logs : `docker compose -f docker-compose.prod.yml logs`
2. Vérifier la configuration : `cat backend/.env`
3. Tester la connectivité : `curl http://localhost:80`

### **Problème d'authentification :**

1. Vérifier `SESSION_COOKIE_SECURE` et `CSRF_COOKIE_SECURE`
2. Pour HTTP : `False`
3. Pour HTTPS : `True`

### **Problème de fichiers statiques :**

1. Vérifier Nginx : `docker compose -f docker-compose.prod.yml logs nginx`
2. Vérifier les permissions : `ls -la /var/www/static/`

## 📞 Support

En cas de problème, vérifiez :
1. Les logs Docker
2. La configuration `.env`
3. La connectivité réseau
4. Les permissions de fichiers


Le déploiement GitHub Actions devrait maintenant fonctionner..

---

## 🤖 Auto-déploiement professionnel (via Cron)

Créez `/opt/coucou_beaute/deploy-cron.sh` :

```bash
#!/bin/bash
set -euo pipefail
cd /opt/coucou_beaute
LOG=/var/log/coucou_deploy.log
echo "[$(date '+%F %T')] 🔄 Check updates" | tee -a "$LOG"
git fetch origin main
LOCAL=$(git rev-parse HEAD || echo "")
REMOTE=$(git rev-parse origin/main || echo "")
if [ -n "$REMOTE" ] && [ "$LOCAL" != "$REMOTE" ]; then
  echo "[$(date '+%F %T')] 🆕 Changes detected -> deploy" | tee -a "$LOG"
  ./deploy-simple.sh | tee -a "$LOG"
else
  echo "[$(date '+%F %T')] ✅ No changes" | tee -a "$LOG"
fi
```

Rendez-le exécutable et planifiez :

```bash
chmod +x /opt/coucou_beaute/deploy-cron.sh
crontab -e
# */2 * * * * /opt/coucou_beaute/deploy-cron.sh >/dev/null 2>&1
```

Cette solution surveille origin/main et déploie automatiquement en cas de nouveaux commits, avec migrations et collectstatic gérées par `deploy-simple.sh`.