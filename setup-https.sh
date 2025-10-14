#!/bin/bash
# Script pour configurer HTTPS avec Let's Encrypt

set -euo pipefail

# Configuration
DOMAIN="196.203.120.35"
EMAIL="admin@coucoubeaute.com"  # Remplacez par votre email
PROJECT_DIR="/opt/coucou_beaute"
NGINX_CONTAINER="coucou_nginx"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "🔒 Configuration HTTPS pour $DOMAIN"

# Aller dans le répertoire du projet
cd "$PROJECT_DIR" || {
    log "❌ Impossible d'accéder au répertoire $PROJECT_DIR"
    exit 1
}

# Créer les dossiers nécessaires
log "📁 Création des dossiers SSL..."
mkdir -p ssl certbot/www certbot/letsencrypt

# Arrêter Nginx temporairement
log "⏹️ Arrêt de Nginx..."
docker compose -f docker-compose.prod.yml stop nginx || true

# Démarrer un conteneur temporaire pour les challenges Let's Encrypt
log "🌐 Démarrage du conteneur temporaire pour Let's Encrypt..."
docker run -d --name certbot-temp \
    -p 80:80 \
    -v "$PROJECT_DIR/certbot/www:/var/www/certbot" \
    nginx:alpine

# Attendre que le conteneur soit prêt
sleep 5

# Obtenir le certificat SSL
log "🔐 Obtention du certificat SSL avec Let's Encrypt..."
docker run --rm \
    -v "$PROJECT_DIR/certbot/www:/var/www/certbot" \
    -v "$PROJECT_DIR/certbot/letsencrypt:/etc/letsencrypt" \
    certbot/certbot certonly \
    --webroot \
    --webroot-path=/var/www/certbot \
    --email "$EMAIL" \
    --agree-tos \
    --no-eff-email \
    --force-renewal \
    -d "$DOMAIN"

# Arrêter le conteneur temporaire
log "🧹 Nettoyage du conteneur temporaire..."
docker stop certbot-temp || true
docker rm certbot-temp || true

# Copier les certificats vers le dossier ssl
log "📋 Copie des certificats..."
if [ -f "certbot/letsencrypt/live/$DOMAIN/fullchain.pem" ]; then
    cp "certbot/letsencrypt/live/$DOMAIN/fullchain.pem" "ssl/"
    cp "certbot/letsencrypt/live/$DOMAIN/privkey.pem" "ssl/"
    log "✅ Certificats copiés avec succès"
else
    log "❌ Erreur: Certificats non trouvés"
    exit 1
fi

# Redémarrer Nginx avec HTTPS
log "🚀 Redémarrage de Nginx avec HTTPS..."
docker compose -f docker-compose.prod.yml up -d nginx

# Vérifier que HTTPS fonctionne
log "🔍 Vérification de HTTPS..."
sleep 10

if curl -kfsS "https://$DOMAIN/" > /dev/null 2>&1; then
    log "✅ HTTPS configuré avec succès!"
    log "🌐 Votre site est maintenant accessible sur https://$DOMAIN"
else
    log "⚠️ HTTPS configuré mais test non concluant"
    log "🔍 Vérifiez les logs: docker logs $NGINX_CONTAINER"
fi

# Configurer le renouvellement automatique
log "⏰ Configuration du renouvellement automatique..."
cat > renew-ssl.sh << 'EOF'
#!/bin/bash
cd /opt/coucou_beaute
docker run --rm \
    -v "$(pwd)/certbot/www:/var/www/certbot" \
    -v "$(pwd)/certbot/letsencrypt:/etc/letsencrypt" \
    certbot/certbot renew --quiet

# Redémarrer Nginx si les certificats ont été renouvelés
if [ $? -eq 0 ]; then
    cp certbot/letsencrypt/live/196.203.120.35/fullchain.pem ssl/
    cp certbot/letsencrypt/live/196.203.120.35/privkey.pem ssl/
    docker compose -f docker-compose.prod.yml restart nginx
fi
EOF

chmod +x renew-ssl.sh

# Ajouter au crontab pour renouvellement automatique
(crontab -l 2>/dev/null; echo "0 3 * * * /opt/coucou_beaute/renew-ssl.sh") | crontab -

log "🎉 Configuration HTTPS terminée!"
log "📅 Renouvellement automatique configuré (tous les jours à 3h)"
