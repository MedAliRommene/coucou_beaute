#!/bin/bash
# Script pour corriger les permissions d'upload en production

set -euo pipefail

PROJECT_DIR="/opt/coucou_beaute"
LOG_FILE="/var/log/coucou_fix_uploads.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🔧 Correction des permissions d'upload..."

cd "$PROJECT_DIR" || { log "❌ Impossible d'accéder au répertoire $PROJECT_DIR"; exit 1; }

# 1. Créer les dossiers media s'ils n'existent pas
log "📁 Création des dossiers media..."
mkdir -p media/applications
mkdir -p media/professionals/avatars
mkdir -p media/static

# 2. Définir les permissions correctes
log "🔐 Configuration des permissions..."
chmod -R 755 media/
chmod -R 777 media/applications/
chmod -R 777 media/professionals/

# 3. Vérifier que le conteneur web peut écrire
log "🐳 Vérification des permissions Docker..."
docker compose -f docker-compose.prod.yml exec -T web touch /app/media/test_write.txt || true
if docker compose -f docker-compose.prod.yml exec -T web test -f /app/media/test_write.txt; then
    log "✅ Le conteneur web peut écrire dans /app/media"
    docker compose -f docker-compose.prod.yml exec -T web rm -f /app/media/test_write.txt
else
    log "❌ Le conteneur web ne peut pas écrire dans /app/media"
fi

# 4. Redémarrer Nginx pour appliquer les nouvelles configs
log "🔄 Redémarrage de Nginx..."
docker compose -f docker-compose.prod.yml restart nginx

log "✅ Correction des permissions terminée!"
