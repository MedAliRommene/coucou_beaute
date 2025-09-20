#!/bin/bash
# Script de déploiement automatique par cron
# Vérifie les modifications GitHub toutes les 5 minutes

PROJECT_DIR="/opt/coucou_beaute"
LOG_FILE="/var/log/coucou_beaute_deploy.log"
LOCK_FILE="/tmp/coucou_beaute_deploy.lock"

# Fonction de log
log_message() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Vérifier si un déploiement est déjà en cours
if [ -f "$LOCK_FILE" ]; then
    log_message "⚠️ Déploiement déjà en cours - ignoré"
    exit 0
fi

# Créer le fichier de verrouillage
touch "$LOCK_FILE"

# Fonction de nettoyage
cleanup() {
    rm -f "$LOCK_FILE"
    log_message "🧹 Nettoyage terminé"
}
trap cleanup EXIT

log_message "🔍 Vérification des modifications..."

# Aller dans le répertoire du projet
cd "$PROJECT_DIR" || exit 1

# Récupérer les dernières informations
git fetch origin main

# Vérifier s'il y a des modifications
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" = "$REMOTE" ]; then
    log_message "ℹ️ Aucune modification détectée"
    exit 0
fi

log_message "📝 Modifications détectées - Début du déploiement..."

# Sauvegarder l'ancien .env
if [ -f "backend/.env" ]; then
    cp "backend/.env" "backend/.env.backup.$(date +%s)"
    log_message "💾 Sauvegarde de .env"
fi

# Récupérer les modifications
git pull origin main

# Créer le fichier .env si nécessaire
if [ ! -f "backend/.env" ]; then
    cp "backend/env.example" "backend/.env"
    log_message "⚠️ Fichier .env créé à partir de env.example"
fi

# Arrêter les services
log_message "⏹️ Arrêt des services..."
docker compose -f docker-compose.prod.yml down

# Reconstruire et redémarrer
log_message "🔨 Reconstruction et redémarrage..."
docker compose -f docker-compose.prod.yml up -d --build

# Vérifier le statut
if docker compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    log_message "✅ Déploiement terminé avec succès!"
else
    log_message "❌ Erreur lors du déploiement"
    exit 1
fi

log_message "🎉 Déploiement automatique terminé"
