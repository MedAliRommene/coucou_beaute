#!/bin/bash
# Script de déploiement simple et robuste

set -e  # Arrêter en cas d'erreur

# Configuration
PROJECT_DIR="/opt/coucou_beaute"
LOG_FILE="/var/log/coucou_deploy.log"

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
git reset --hard origin/main

# Créer le fichier .env si nécessaire
if [ ! -f "backend/.env" ]; then
    cp "backend/env.example" "backend/.env"
    log "⚠️ Fichier .env créé à partir de env.example"
fi

# Arrêter les services existants
log "⏹️ Arrêt des services..."
docker compose -f docker-compose.prod.yml down || true

# Nettoyer les images inutilisées
log "🧹 Nettoyage des images Docker..."
docker system prune -f

# Reconstruire et redémarrer
log "🔨 Reconstruction et redémarrage..."
docker compose -f docker-compose.prod.yml up -d --build

# Attendre que les services soient prêts
log "⏳ Attente du démarrage des services..."
sleep 30

# Vérifier le statut
log "🔍 Vérification du statut..."
if docker compose -f docker-compose.prod.yml ps | grep -q "Up"; then
    log "✅ Déploiement terminé avec succès!"
    
    # Afficher les services
    docker compose -f docker-compose.prod.yml ps
    
    # Test de l'application
    if curl -f http://localhost:8000 > /dev/null 2>&1; then
        log "✅ Application accessible sur http://localhost:8000"
    else
        log "⚠️ Application non accessible - vérifiez les logs"
    fi
else
    log "❌ Erreur lors du déploiement"
    docker compose -f docker-compose.prod.yml logs
    exit 1
fi

log "🎉 Déploiement terminé!"
