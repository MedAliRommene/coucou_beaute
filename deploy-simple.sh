#!/bin/bash
# Script de déploiement simple et robuste

set -euo pipefail  # Arrêter en cas d'erreur, variables non définies et erreurs de pipe

# Configuration
PROJECT_DIR="/opt/coucou_beaute"
LOG_FILE="/var/log/coucou_deploy.log"
COMPOSE_FILE="docker-compose.prod.yml"
WEB_SERVICE="web"

# Fonction de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "🚀 Début du déploiement..."

# Aller dans le répertoire du projet
cd "$PROJECT_DIR" || {
    log "❌ Impossible d'accéder au répertoire $PROJECT_DIR"
    exit 1
}

# Sauvegarder l'ancien .env
if [ -f "backend/.env" ]; then
    cp "backend/.env" "backend/.env.backup.$(date +%s)"
    log "💾 Sauvegarde de .env"
fi

# Récupérer les dernières modifications
log "📥 Récupération des modifications..."
git fetch origin main
LOCAL_COMMIT=$(git rev-parse HEAD || echo "")
REMOTE_COMMIT=$(git rev-parse origin/main || echo "")
if [ -n "$REMOTE_COMMIT" ] && [ "$LOCAL_COMMIT" != "$REMOTE_COMMIT" ]; then
  git reset --hard origin/main
  log "✅ Code synchronisé sur origin/main ($REMOTE_COMMIT)"
else
  log "ℹ️ Aucun nouveau commit à déployer (HEAD=$LOCAL_COMMIT)"
fi

# Créer le fichier .env si nécessaire
if [ ! -f "backend/.env" ]; then
    cp "backend/env.example" "backend/.env"
    log "⚠️ Fichier .env créé à partir de env.example"
fi

# Arrêter les services existants
log "⏹️ Arrêt des services..."
docker compose -f "$COMPOSE_FILE" down || true

# Nettoyer les images inutilisées
log "🧹 Nettoyage des images Docker..."
docker system prune -f

# Reconstruire et redémarrer
log "🔨 Reconstruction et redémarrage..."
docker compose -f "$COMPOSE_FILE" up -d --build

# Attente active DB healthy (si service db présent)
if docker compose -f "$COMPOSE_FILE" ps db >/dev/null 2>&1; then
  log "⏳ Attente de la base de données..."
  for i in $(seq 1 30); do
    if docker compose -f "$COMPOSE_FILE" ps | grep -q "coucou_db\s\+.*(healthy)"; then
      log "✅ Base de données OK"
      break
    fi
    sleep 2
  done
fi

# Migrations & collectstatic (avec retries)
run_in_web() {
  docker compose -f "$COMPOSE_FILE" exec -T "$WEB_SERVICE" bash -lc "$*"
}

log "⚙️ Migrations Django..."
for i in 1 2 3; do
  if run_in_web "python manage.py migrate --noinput"; then
    OK=1; break; fi; log "⏳ Retry migrations ($i)"; sleep 3; done

log "🧱 Collectstatic..."
for i in 1 2 3; do
  if run_in_web "python manage.py collectstatic --noinput --no-post-process"; then
    OK=1; break; fi; log "⏳ Retry collectstatic ($i)"; sleep 3; done

# Attendre que les services soient prêts
log "⏳ Attente du démarrage des services..."
# Boucle santé du service web (attente progressive)
for i in 5 10 15 20 25 30; do
  log "⏳ Vérification santé web (t+$i s)..."
  if docker compose -f "$COMPOSE_FILE" ps | grep -q "coucou_web\s\+.*Up"; then
    break
  fi
  sleep 5
done

# Vérifier le statut
log "🔍 Vérification du statut..."
if docker compose -f "$COMPOSE_FILE" ps | grep -q "Up"; then
    log "✅ Déploiement terminé avec succès!"
    
    # Afficher les services
    docker compose -f "$COMPOSE_FILE" ps
    
    # Test de l'application
    if curl -fsS http://localhost:8000/ > /dev/null 2>&1; then
        log "✅ Application HTTP OK sur http://localhost:8000"
    else
        log "⚠️ Test HTTP interne non concluant"
    fi

    # Si HTTPS configuré sur nginx, tester 443 aussi
    if docker compose -f "$COMPOSE_FILE" ps | grep -q "coucou_nginx"; then
      if curl -kfsS https://localhost/ > /dev/null 2>&1; then
        log "✅ HTTPS via Nginx OK"
      else
        log "ℹ️ HTTPS non encore disponible (cert ou config manquante)"
      fi
    else
        log "ℹ️ Nginx non présent - skip test HTTPS"
    fi
else
    log "❌ Erreur lors du déploiement"
    docker compose -f "$COMPOSE_FILE" logs --tail=200
    exit 1
fi

log "🎉 Déploiement terminé!"
