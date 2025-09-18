# 🚀 CI/CD - Coucou Beauté

## 📋 Vue d'ensemble

Ce projet utilise GitHub Actions pour automatiser les tests, la construction et le déploiement de l'application Coucou Beauté.

## 🔄 Workflows Disponibles

### **1. 🧪 Tests & Quality Checks (`test.yml`)**
- **Déclencheur :** Pull Requests vers `main` ou `develop`
- **Fonctions :**
  - Tests Python/Django
  - Tests Flutter/Mobile
  - Vérification de la qualité du code
  - Scan de sécurité

### **2. 🚀 Déploiement Production (`deploy.yml`)**
- **Déclencheur :** Push sur `main` ou déploiement manuel
- **Fonctions :**
  - Tests et validation
  - Construction des images Docker
  - Déploiement automatique sur le serveur
  - Notifications

### **3. 🏷️ Releases (`release.yml`)**
- **Déclencheur :** Tags de version ou déploiement manuel
- **Fonctions :**
  - Création de releases GitHub
  - Déploiement de versions spécifiques
  - Génération de changelog

## 🛠️ Configuration

### **Secrets GitHub Requis :**

| Secret | Description | Exemple |
|--------|-------------|---------|
| `DOCKER_USERNAME` | Nom d'utilisateur Docker Hub | `coucoubeaute` |
| `DOCKER_PASSWORD` | Token Docker Hub | `dckr_pat_...` |
| `SSH_PRIVATE_KEY` | Clé privée SSH | `-----BEGIN OPENSSH PRIVATE KEY-----` |
| `SERVER_USER` | Utilisateur du serveur | `ubuntu` |
| `SERVER_HOST` | Adresse du serveur | `196.203.120.35` |

### **Configuration du Serveur :**

```bash
# 1. Installation des prérequis
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh

# 2. Installation Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 3. Cloner le repository
git clone <votre-repo-url> /opt/coucou_beaute
cd /opt/coucou_beaute

# 4. Configurer l'environnement
cp backend/env.example backend/.env
nano backend/.env
```

## 🚀 Utilisation

### **Déploiement Automatique :**

1. **Faire un commit sur `main` :**
   ```bash
   git add .
   git commit -m "feat: nouvelle fonctionnalité"
   git push origin main
   ```

2. **Le déploiement se lance automatiquement :**
   - Tests et validation
   - Construction des images Docker
   - Déploiement sur le serveur
   - Vérification du déploiement

### **Déploiement Manuel :**

1. Allez sur l'onglet **Actions** de votre repository
2. Sélectionnez le workflow **Deploy to Production**
3. Cliquez sur **Run workflow**
4. Sélectionnez la branche et cliquez sur **Run workflow**

### **Création d'une Release :**

1. **Via Git :**
   ```bash
   git tag v1.0.0
   git push origin v1.0.0
   ```

2. **Via GitHub :**
   - Allez sur **Releases**
   - Cliquez sur **Create a new release**
   - Entrez le tag de version
   - Cliquez sur **Publish release**

## 🔍 Monitoring

### **Logs GitHub Actions :**
- Allez dans **Actions** > [Workflow] > [Job] > [Step]
- Consultez les logs en temps réel

### **Logs du Serveur :**
```bash
# Logs de tous les services
docker compose -f docker-compose.prod.yml logs

# Logs d'un service spécifique
docker compose -f docker-compose.prod.yml logs web
docker compose -f docker-compose.prod.yml logs db
docker compose -f docker-compose.prod.yml logs nginx

# Logs en temps réel
docker compose -f docker-compose.prod.yml logs -f
```

### **État des Services :**
```bash
# Vérifier l'état des conteneurs
docker compose -f docker-compose.prod.yml ps

# Vérifier l'utilisation des ressources
docker stats

# Vérifier la connectivité
curl http://localhost:80
```

## 🛠️ Dépannage

### **Problèmes Courants :**

1. **Échec des tests :**
   - Vérifiez les logs GitHub Actions
   - Corrigez les erreurs de code
   - Relancez le workflow

2. **Échec du déploiement :**
   - Vérifiez la configuration SSH
   - Vérifiez les secrets GitHub
   - Vérifiez la connectivité au serveur

3. **Problème de connexion SSH :**
   - Vérifiez que la clé SSH est correcte
   - Vérifiez que l'utilisateur a les bonnes permissions
   - Testez la connexion manuellement

4. **Problème Docker :**
   - Vérifiez que Docker est installé sur le serveur
   - Vérifiez que l'utilisateur peut exécuter Docker
   - Vérifiez les logs Docker

### **Commandes de Debug :**

```bash
# Test de connexion SSH
ssh -i ~/.ssh/id_rsa user@server-ip

# Test de construction Docker
docker build -t test-image ./backend

# Test de déploiement local
docker compose -f docker-compose.prod.yml up -d

# Vérification des services
docker compose -f docker-compose.prod.yml ps
```

## 📚 Documentation

- **Configuration des secrets :** `.github/SECRETS.md`
- **Guide de déploiement :** `DEPLOYMENT.md`
- **Configuration des environnements :** `backend/env.example`

## 🆘 Support

En cas de problème :
1. Consultez les logs GitHub Actions
2. Vérifiez la configuration des secrets
3. Testez la connectivité SSH
4. Vérifiez les logs Docker sur le serveur
5. Consultez la documentation GitHub Actions
