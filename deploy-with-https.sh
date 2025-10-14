#!/bin/bash
# Script de déploiement complet avec HTTPS

set -euo pipefail

PROJECT_DIR="/opt/coucou_beaute"
LOG_FILE="/var/log/coucou_deploy.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🚀 Déploiement complet avec HTTPS..."

cd "$PROJECT_DIR"

# Récupérer les modifications
log "📥 Récupération des modifications..."
git pull origin main

# Arrêter tous les services
log "⏹️ Arrêt des services..."
docker compose -f docker-compose.prod.yml down

# Nettoyer
log "🧹 Nettoyage..."
docker system prune -f

# Reconstruire et redémarrer
log "🔨 Reconstruction et redémarrage..."
docker compose -f docker-compose.prod.yml up -d --build

# Attendre que la DB soit prête
log "⏳ Attente de la base de données..."
for i in $(seq 1 30); do
    if docker compose -f docker-compose.prod.yml ps | grep -q "coucou_db.*healthy"; then
        log "✅ Base de données OK"
        break
    fi
    sleep 2
done

# Migrations et collectstatic
log "⚙️ Migrations Django..."
docker compose -f docker-compose.prod.yml exec -T web python manage.py migrate --noinput

log "🧱 Collectstatic..."
docker compose -f docker-compose.prod.yml exec -T web python manage.py collectstatic --noinput --no-post-process

# Attendre que les services soient prêts
log "⏳ Attente du démarrage des services..."
sleep 30

# Tests
log "🔍 Tests de connectivité..."

# Test HTTP (redirection)
if curl -fsS "http://196.203.120.35/" > /dev/null 2>&1; then
    log "✅ Redirection HTTP vers HTTPS OK"
else
    log "⚠️ Test HTTP non concluant"
fi

# Test HTTPS
if curl -kfsS "https://196.203.120.35/" > /dev/null 2>&1; then
    log "✅ HTTPS OK"
    log "🌐 Site accessible sur https://196.203.120.35"
else
    log "❌ Problème avec HTTPS"
    log "🔍 Vérifiez les logs: docker logs coucou_nginx"
fi

log "🎉 Déploiement terminé!"
