#!/bin/bash
# Script de déploiement ultra-simple - UNE SEULE COMMANDE

set -euo pipefail

PROJECT_DIR="/opt/coucou_beaute"
LOG_FILE="/var/log/coucou_deploy.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🚀 Déploiement rapide Coucou Beauté..."

cd "$PROJECT_DIR"

# Récupérer les modifications
log "📥 Récupération des modifications..."
git pull origin main

# Redéployer
log "🔄 Redéploiement..."
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d --build

# Attendre que les services soient prêts
log "⏳ Attente des services..."
sleep 30

# Migrations et collectstatic
log "⚙️ Migrations et collectstatic..."
docker compose -f docker-compose.prod.yml exec -T web python manage.py migrate --noinput
docker compose -f docker-compose.prod.yml exec -T web python manage.py collectstatic --noinput --no-post-process

# Test final
log "🔍 Test final..."
if curl -kfsS "https://196.203.120.35/" > /dev/null 2>&1; then
    log "✅ Déploiement réussi! Site accessible sur https://196.203.120.35"
else
    log "⚠️ Déploiement terminé mais test non concluant"
fi

log "🎉 Terminé!"
