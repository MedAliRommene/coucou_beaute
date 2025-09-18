# 🔐 Guide de Configuration des Secrets GitHub - Coucou Beauté

## 📋 Secrets Requis pour Votre Projet

Basé sur votre configuration actuelle, voici les secrets que vous devez configurer :

### **1. 🐳 Docker Hub (pour les images)**
- **Nom du secret :** `DOCKER_USERNAME`
- **Valeur :** `coucoubeaute` (ou votre nom d'utilisateur Docker Hub)
- **Description :** Nom d'utilisateur pour Docker Hub

- **Nom du secret :** `DOCKER_PASSWORD`
- **Valeur :** Votre token d'accès Docker Hub
- **Description :** Token d'accès pour Docker Hub

### **2. 🖥️ Serveur de Production**
- **Nom du secret :** `SSH_PRIVATE_KEY`
- **Valeur :** Votre clé privée SSH
- **Description :** Clé privée pour accéder au serveur 196.203.120.35

- **Nom du secret :** `SERVER_USER`
- **Valeur :** `root` (ou `ubuntu` selon votre configuration)
- **Description :** Utilisateur SSH du serveur

- **Nom du secret :** `SERVER_HOST`
- **Valeur :** `196.203.120.35`
- **Description :** Adresse IP de votre serveur

### **3. 🗄️ Base de Données (optionnel)**
- **Nom du secret :** `POSTGRES_PASSWORD`
- **Valeur :** `admin` (votre mot de passe actuel)
- **Description :** Mot de passe de la base de données

- **Nom du secret :** `REDIS_PASSWORD`
- **Valeur :** `coucou_redis_pass`
- **Description :** Mot de passe Redis

## 🔧 Comment Configurer les Secrets

### **Étape 1 : Accéder aux Secrets**
1. Allez sur votre repository GitHub : https://github.com/MedAliRommene/coucou_beaute
2. Cliquez sur **Settings** (en haut à droite)
3. Dans le menu de gauche, cliquez sur **Secrets and variables** > **Actions**

### **Étape 2 : Ajouter les Secrets**
1. Cliquez sur **New repository secret**
2. Entrez le nom du secret (ex: `DOCKER_USERNAME`)
3. Entrez la valeur du secret
4. Cliquez sur **Add secret**

### **Étape 3 : Vérifier la Configuration**
- Tous les secrets requis doivent être listés
- Les secrets sont masqués (****) pour la sécurité

## 🚀 Configuration du Serveur

### **Étape 1 : Connexion au Serveur**
```bash
# Connectez-vous à votre serveur
ssh root@196.203.120.35
# ou
ssh ubuntu@196.203.120.35
```

### **Étape 2 : Exécuter le Script de Configuration**
```bash
# Téléchargez le script
wget https://raw.githubusercontent.com/MedAliRommene/coucou_beaute/main/setup-server.sh

# Rendez-le exécutable
chmod +x setup-server.sh

# Exécutez-le
./setup-server.sh
```

### **Étape 3 : Configuration de l'Environnement**
```bash
# Allez dans le répertoire du projet
cd /opt/coucou_beaute

# Configurez l'environnement
nano backend/.env
```

**Configuration recommandée pour votre .env :**
```bash
# Configuration Django
DJANGO_DEBUG=False
DJANGO_SECRET_KEY=-m_k*toc2ke#_873v&i-^&3e%9*8=&_(12dk8*7x19r5t&rq3v
DJANGO_ALLOWED_HOSTS=196.203.120.35,127.0.0.1,localhost,web

# Base de données
POSTGRES_DB=coucou_prod
POSTGRES_USER=coucou
POSTGRES_PASSWORD=admin
POSTGRES_HOST=db
POSTGRES_PORT=5432

# Sécurité
CSRF_TRUSTED_ORIGINS=http://196.203.120.35,http://127.0.0.1
DJANGO_CORS_ORIGINS=http://196.203.120.35
CSRF_COOKIE_SECURE=False
SESSION_COOKIE_SECURE=False

# Email
EMAIL_BACKEND=django.core.mail.backends.smtp.EmailBackend
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USE_TLS=True
EMAIL_HOST_USER=dalyrommene@gmail.com
EMAIL_HOST_PASSWORD=@AzertyDaly9855
DEFAULT_FROM_EMAIL=dalyrommene@gmail.com
SERVER_EMAIL=dalyrommene@gmail.com

# Docker
DOCKER_USERNAME=coucoubeaute
```

### **Étape 4 : Premier Déploiement**
```bash
# Déployez l'application
cd /opt/coucou_beaute
./deploy.sh
```

## 🧪 Test du CI/CD

### **Test 1 : Déploiement Automatique**
1. Faites un petit changement dans votre code
2. Committez et poussez :
   ```bash
   git add .
   git commit -m "test: test CI/CD deployment"
   git push origin main
   ```
3. Allez sur GitHub > Actions
4. Vérifiez que le workflow se lance automatiquement

### **Test 2 : Vérification du Site**
1. Allez sur http://196.203.120.35
2. Vérifiez que le site fonctionne
3. Testez la connexion admin : http://196.203.120.35/admin/

## 🔍 Dépannage

### **Problème de Connexion SSH :**
```bash
# Testez la connexion
ssh -i ~/.ssh/id_rsa root@196.203.120.35

# Vérifiez les permissions
chmod 600 ~/.ssh/id_rsa
```

### **Problème de Déploiement :**
```bash
# Vérifiez les logs
cd /opt/coucou_beaute
docker compose -f docker-compose.prod.yml logs

# Vérifiez l'état des services
docker compose -f docker-compose.prod.yml ps
```

### **Problème de Site :**
```bash
# Vérifiez Nginx
systemctl status nginx
nginx -t

# Vérifiez les logs Nginx
tail -f /var/log/nginx/error.log
```

## 📞 Support

En cas de problème :
1. Vérifiez les logs GitHub Actions
2. Vérifiez les logs Docker sur le serveur
3. Vérifiez la configuration des secrets
4. Vérifiez la connectivité SSH
5. Consultez la documentation dans `/opt/coucou_beaute/DEPLOYMENT.md`

## ✅ Checklist de Configuration

- [ ] Secrets GitHub configurés
- [ ] Serveur configuré avec le script
- [ ] Fichier .env configuré
- [ ] Premier déploiement réussi
- [ ] Site accessible sur http://196.203.120.35
- [ ] Connexion admin fonctionnelle
- [ ] CI/CD testé et fonctionnel

**🎉 Une fois tous ces éléments cochés, votre CI/CD est prêt !**
