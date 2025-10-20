#!/bin/bash
# =========================================================
# COUCOU BEAUTÉ - AUTO-DEPLOYMENT CRON SCRIPT
# =========================================================
# Ce script est conçu pour être exécuté automatiquement
# par cron pour surveiller les changements git et déployer
# automatiquement si nécessaire.
#
# Configuration cron recommandée:
# */15 * * * * /opt/coucou_beaute/deploy-cron.sh >> /var/log/coucou_deploy_cron.log 2>&1
# =========================================================

set -euo pipefail

# Configuration
PROJECT_DIR="/opt/coucou_beaute"
LOG_FILE="/var/log/coucou_deploy_cron.log"
LOCK_FILE="/tmp/coucou_deploy.lock"
BRANCH="main"

# Fonction de logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

# Fonction de nettoyage
cleanup() {
    rm -f "$LOCK_FILE"
}
trap cleanup EXIT

# Vérifier qu'on n'a pas déjà un déploiement en cours
if [ -f "$LOCK_FILE" ]; then
    log "⚠️ Déploiement déjà en cours (lock file existe). Skip."
    exit 0
fi

# Créer le lock file
touch "$LOCK_FILE"

log "🔍 Vérification des mises à jour..."

# Aller dans le répertoire du projet
cd "$PROJECT_DIR" || {
    log "❌ Erreur: Impossible d'accéder à $PROJECT_DIR"
    exit 1
}

# Récupérer les informations git
git fetch origin "$BRANCH" 2>&1 | tee -a "$LOG_FILE"

# Comparer local et remote
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse "origin/$BRANCH")

if [ "$LOCAL" = "$REMOTE" ]; then
    log "✅ Déjà à jour (commit: ${LOCAL:0:7}). Aucun déploiement nécessaire."
    exit 0
fi

log "🆕 Nouveaux commits détectés:"
log "   Local:  ${LOCAL:0:7}"
log "   Remote: ${REMOTE:0:7}"
log ""

# Afficher les commits à déployer
log "📋 Commits à déployer:"
git log --oneline "$LOCAL".."$REMOTE" | tee -a "$LOG_FILE"
log ""

# Lancer le déploiement
log "🚀 Démarrage du déploiement automatique..."
if sudo bash "$PROJECT_DIR/deploy.sh" 2>&1 | tee -a "$LOG_FILE"; then
    log "✅ Déploiement automatique réussi!"
    log "   Nouveau commit: ${REMOTE:0:7}"
    
    # Envoyer une notification (optionnel - peut être configuré)
    # curl -X POST "https://api.example.com/notify" \
    #   -d "message=Coucou Beauté déployé avec succès (${REMOTE:0:7})"
else
    log "❌ Échec du déploiement automatique!"
    log "   Veuillez vérifier les logs pour plus de détails."
    
    # Envoyer une alerte (optionnel)
    # curl -X POST "https://api.example.com/alert" \
    #   -d "message=Échec du déploiement automatique Coucou Beauté"
    
    exit 1
fi

log "🎉 Auto-déploiement terminé avec succès!"

