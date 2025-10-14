#!/bin/bash
# Script pour corriger le fichier .env pour HTTPS

set -euo pipefail

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

log "🔧 Correction du fichier .env pour HTTPS..."

cd /opt/coucou_beaute/backend

# Vérifier si .env existe
if [ ! -f .env ]; then
    log "❌ Fichier .env non trouvé. Création à partir de env.example..."
    cp env.example .env
fi

# Fonction pour ajouter ou mettre à jour une variable
update_env_var() {
    local key=$1
    local value=$2
    local file=".env"
    
    if grep -q "^${key}=" "$file"; then
        # La variable existe, la mettre à jour
        sed -i "s|^${key}=.*|${key}=${value}|" "$file"
        log "✅ Mise à jour: ${key}=${value}"
    else
        # La variable n'existe pas, l'ajouter
        echo "${key}=${value}" >> "$file"
        log "✅ Ajouté: ${key}=${value}"
    fi
}

log "📝 Configuration des variables d'environnement..."

# Configuration Django de base
update_env_var "DJANGO_DEBUG" "False"
update_env_var "DJANGO_ALLOWED_HOSTS" "196.203.120.35,localhost,127.0.0.1"

# Configuration CSRF pour HTTPS
update_env_var "CSRF_TRUSTED_ORIGINS" "https://196.203.120.35,http://196.203.120.35"

# Configuration CORS
update_env_var "DJANGO_CORS_ORIGINS" "https://196.203.120.35,http://196.203.120.35"

# Cookies sécurisés (False car certificat auto-signé)
update_env_var "CSRF_COOKIE_SECURE" "False"
update_env_var "SESSION_COOKIE_SECURE" "False"

# HTTPS (False car certificat auto-signé)
update_env_var "SECURE_SSL_REDIRECT" "False"

log "✅ Fichier .env configuré pour HTTPS!"
log "📋 Vérification du fichier .env:"
cat .env | grep -E "DJANGO_ALLOWED_HOSTS|CSRF_TRUSTED_ORIGINS|DJANGO_DEBUG"

log "🔄 Redémarrage des services pour appliquer les changements..."
cd /opt/coucou_beaute
docker compose -f docker-compose.prod.yml restart web

log "⏳ Attente du redémarrage (30 secondes)..."
sleep 30

log "🧪 Test de connectivité..."
if curl -kfsS "https://196.203.120.35/" > /dev/null 2>&1; then
    log "✅ Site accessible! Testez maintenant dans le navigateur."
else
    log "⚠️ Test non concluant. Vérifiez les logs: docker logs coucou_web"
fi

log "🎉 Configuration terminée!"
