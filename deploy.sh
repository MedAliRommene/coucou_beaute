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

# S'assurer que Compose a le mot de passe DB
if [ ! -f .env ] || ! grep -q "^POSTGRES_PASSWORD=" .env; then
    log "🔐 Création/MAJ du .env (POSTGRES_PASSWORD) pour Docker Compose"
    printf "POSTGRES_PASSWORD=admin\n" >> .env
fi

# Redéployer
log "🔄 Redéploiement..."
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d --build

# Attendre DB healthy
log "⏳ Attente de la base de données (healthy)..."
for i in $(seq 1 30); do
    if docker compose -f docker-compose.prod.yml ps | grep -q "db\s\+.*(healthy)"; then
        log "✅ Base de données prête"
        break
    fi
    sleep 2
done

# Bootstrap DB (idempotent)
log "🧩 Vérification/Création rôle et base PostgreSQL..."
docker exec -i coucou_db psql -U postgres -tc "SELECT 1 FROM pg_roles WHERE rolname='coucou'" | grep -q 1 || \
    docker exec -i coucou_db psql -U postgres -c "CREATE USER coucou WITH PASSWORD 'admin';"
docker exec -i coucou_db psql -U postgres -tc "SELECT 1 FROM pg_database WHERE datname='coucou_prod'" | grep -q 1 || \
    docker exec -i coucou_db psql -U postgres -c "CREATE DATABASE coucou_prod WITH OWNER coucou ENCODING 'UTF8';"
docker exec -i coucou_db psql -U postgres -d coucou_prod -c "GRANT ALL ON SCHEMA public TO coucou;" >/dev/null 2>&1 || true

# Migrations et collectstatic
log "⚙️ Migrations et collectstatic..."
docker compose -f docker-compose.prod.yml exec -T web python manage.py migrate --noinput || true
docker compose -f docker-compose.prod.yml exec -T web python manage.py collectstatic --noinput || true

# Corriger les permissions d'upload
log "🔧 Correction des permissions d'upload..."
mkdir -p media/applications media/professionals/avatars media/static
chmod -R 755 media/
chmod -R 777 media/applications/ media/professionals/

# Test final
log "🔍 Test final..."
if curl -kfsS "https://196.203.120.35/" > /dev/null 2>&1; then
    log "✅ Déploiement réussi! Site accessible sur https://196.203.120.35"
else
    log "⚠️ Déploiement terminé mais test non concluant"
    log "📄 État des services:"
    docker compose -f docker-compose.prod.yml ps || true
    log "📄 Derniers logs web:"
    docker compose -f docker-compose.prod.yml logs --tail=200 web || true
fi

log "🎉 Terminé!"
