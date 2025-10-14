# 🔒 Configuration HTTPS pour Coucou Beauté

## Vue d'ensemble

Ce guide vous permet de configurer HTTPS avec Let's Encrypt pour votre site Coucou Beauté.

## 📋 Prérequis

- Serveur accessible sur internet
- Domaine ou IP publique (196.203.120.35)
- Ports 80 et 443 ouverts
- Docker et Docker Compose installés

## 🚀 Configuration automatique

### Option 1: Script PowerShell (Recommandé)

```powershell
# Exécuter depuis Windows
.\setup-https.ps1
```

### Option 2: Configuration manuelle

1. **Se connecter au serveur**
```bash
ssh vpsuser@196.203.120.35
cd /opt/coucou_beaute
```

2. **Copier les fichiers de configuration**
```bash
# Les fichiers nginx.conf et setup-https.sh doivent être présents
chmod +x setup-https.sh
```

3. **Exécuter la configuration**
```bash
./setup-https.sh
```

## 🔧 Configuration manuelle détaillée

### 1. Créer les dossiers nécessaires
```bash
mkdir -p ssl certbot/www certbot/letsencrypt
```

### 2. Arrêter Nginx temporairement
```bash
docker compose -f docker-compose.prod.yml stop nginx
```

### 3. Obtenir le certificat SSL
```bash
# Conteneur temporaire pour les challenges
docker run -d --name certbot-temp -p 80:80 -v $(pwd)/certbot/www:/var/www/certbot nginx:alpine

# Obtenir le certificat
docker run --rm \
    -v $(pwd)/certbot/www:/var/www/certbot \
    -v $(pwd)/certbot/letsencrypt:/etc/letsencrypt \
    certbot/certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email admin@coucoubeaute.com \
    --agree-tos \
    --no-eff-email \
    -d 196.203.120.35

# Nettoyer
docker stop certbot-temp && docker rm certbot-temp
```

### 4. Copier les certificats
```bash
cp certbot/letsencrypt/live/196.203.120.35/fullchain.pem ssl/
cp certbot/letsencrypt/live/196.203.120.35/privkey.pem ssl/
```

### 5. Redémarrer avec HTTPS
```bash
docker compose -f docker-compose.prod.yml up -d
```

## 🔄 Renouvellement automatique

Le script configure automatiquement le renouvellement via cron :

```bash
# Vérifier la tâche cron
crontab -l

# Le script de renouvellement est dans renew-ssl.sh
```

## 🧪 Tests

### Test de redirection HTTP → HTTPS
```bash
curl -I http://196.203.120.35/
# Doit retourner: HTTP/1.1 301 Moved Permanently
```

### Test HTTPS
```bash
curl -k https://196.203.120.35/
# Doit retourner le contenu de la page
```

### Test de sécurité SSL
```bash
# Installer sslscan si nécessaire
sudo apt install sslscan

# Tester la configuration SSL
sslscan 196.203.120.35
```

## 🔍 Dépannage

### Problème: Certificat non obtenu
```bash
# Vérifier les logs
docker logs certbot-temp

# Vérifier que le port 80 est accessible
curl -I http://196.203.120.35/.well-known/acme-challenge/test
```

### Problème: HTTPS ne fonctionne pas
```bash
# Vérifier les logs Nginx
docker logs coucou_nginx

# Vérifier la configuration
docker exec coucou_nginx nginx -t
```

### Problème: Certificat expiré
```bash
# Renouveler manuellement
./renew-ssl.sh

# Vérifier l'expiration
openssl x509 -in ssl/fullchain.pem -text -noout | grep "Not After"
```

## 📁 Structure des fichiers

```
/opt/coucou_beaute/
├── nginx.conf              # Configuration Nginx avec HTTPS
├── setup-https.sh          # Script de configuration initiale
├── deploy-https.sh         # Script de déploiement avec HTTPS
├── renew-ssl.sh           # Script de renouvellement automatique
├── ssl/                   # Certificats SSL
│   ├── fullchain.pem
│   └── privkey.pem
└── certbot/               # Dossiers Let's Encrypt
    ├── www/               # Challenges ACME
    └── letsencrypt/       # Certificats Let's Encrypt
```

## 🔐 Sécurité

La configuration inclut :
- ✅ Redirection HTTP → HTTPS
- ✅ Headers de sécurité (HSTS, X-Frame-Options, etc.)
- ✅ Configuration SSL moderne (TLS 1.2/1.3)
- ✅ Compression Gzip
- ✅ Cache optimisé pour les fichiers statiques

## 📞 Support

En cas de problème :
1. Vérifiez les logs : `docker logs coucou_nginx`
2. Testez la connectivité : `curl -I https://196.203.120.35/`
3. Vérifiez les certificats : `openssl x509 -in ssl/fullchain.pem -text -noout`
