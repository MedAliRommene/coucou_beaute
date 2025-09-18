# 🔐 Configuration des Secrets GitHub

## 📋 Secrets Requis

Pour que le CI/CD fonctionne, vous devez configurer les secrets suivants dans votre repository GitHub :

### **1. Docker Hub (pour les images)**
- `DOCKER_USERNAME` : Votre nom d'utilisateur Docker Hub
- `DOCKER_PASSWORD` : Votre token d'accès Docker Hub

### **2. Serveur de Production**
- `SSH_PRIVATE_KEY` : Clé privée SSH pour accéder au serveur
- `SERVER_USER` : Utilisateur SSH du serveur (ex: `root`, `ubuntu`)
- `SERVER_HOST` : Adresse IP ou domaine du serveur (ex: `196.203.120.35`)

### **3. Base de Données (optionnel)**
- `POSTGRES_PASSWORD` : Mot de passe de la base de données
- `REDIS_PASSWORD` : Mot de passe Redis

### **4. Monitoring (optionnel)**
- `GRAFANA_PASSWORD` : Mot de passe Grafana

## 🔧 Comment Configurer les Secrets

### **Étape 1 : Accéder aux Secrets**
1. Allez sur votre repository GitHub
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

## 🚀 Test de Configuration

### **Test du CI/CD :**
1. Faites un commit sur la branche `main`
2. Allez dans l'onglet **Actions** de votre repository
3. Vérifiez que le workflow se lance automatiquement
4. Surveillez les logs pour détecter d'éventuelles erreurs

### **Test de Déploiement :**
1. Créez une Pull Request vers `main`
2. Vérifiez que les tests passent
3. Mergez la PR
4. Vérifiez que le déploiement se lance automatiquement

## 🛠️ Configuration du Serveur

### **Prérequis sur le Serveur :**
```bash
# Installation de Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# Installation de Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Installation de Git
sudo apt update && sudo apt install git -y

# Cloner le repository
git clone <votre-repo-url> /opt/coucou_beaute
cd /opt/coucou_beaute

# Configurer l'environnement
cp backend/env.example backend/.env
nano backend/.env  # Configurer vos valeurs
```

### **Configuration SSH :**
```bash
# Sur votre machine locale
ssh-keygen -t rsa -b 4096 -C "github-actions"
ssh-copy-id -i ~/.ssh/id_rsa.pub user@your-server-ip

# Ajouter la clé privée dans GitHub Secrets
cat ~/.ssh/id_rsa  # Copier le contenu dans SSH_PRIVATE_KEY
```

## 🔍 Dépannage

### **Problèmes Courants :**

1. **Erreur de connexion SSH :**
   - Vérifiez que la clé SSH est correcte
   - Vérifiez que l'utilisateur SSH a les bonnes permissions

2. **Erreur Docker :**
   - Vérifiez que Docker est installé sur le serveur
   - Vérifiez que l'utilisateur peut exécuter Docker

3. **Erreur de permissions :**
   - Vérifiez les permissions des répertoires
   - Vérifiez que l'utilisateur peut écrire dans `/opt/coucou_beaute`

### **Logs de Débogage :**
```bash
# Vérifier les logs GitHub Actions
# Allez dans Actions > [Workflow] > [Job] > [Step]

# Vérifier les logs du serveur
docker compose -f docker-compose.prod.yml logs

# Vérifier l'état des services
docker compose -f docker-compose.prod.yml ps
```

## 📞 Support

En cas de problème :
1. Vérifiez les logs GitHub Actions
2. Vérifiez les logs Docker sur le serveur
3. Vérifiez la configuration des secrets
4. Vérifiez la connectivité SSH
