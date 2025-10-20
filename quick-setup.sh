#!/bin/bash
# =========================================================
# COUCOU BEAUTÉ - QUICK SETUP SCRIPT
# =========================================================
# Script d'installation rapide pour configurer:
# - Permissions correctes
# - Cron auto-déploiement
# - Logs
# - Validation de l'environnement
# =========================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/opt/coucou_beaute"
LOG_FILE="/var/log/coucou_deploy_cron.log"
USER="vpsuser"

# Fonctions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

check_requirement() {
    if command -v "$1" &> /dev/null; then
        log_success "$1 installé"
        return 0
    else
        log_error "$1 manquant"
        return 1
    fi
}

# Banner
clear
echo -e "${BLUE}"
echo "╔════════════════════════════════════════╗"
echo "║   COUCOU BEAUTÉ - QUICK SETUP          ║"
echo "║   Configuration Production Rapide      ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Vérification: Root/Sudo
if [ "$EUID" -eq 0 ]; then
    log_warning "Script exécuté en root. Recommandé: exécuter avec sudo en tant qu'utilisateur normal."
fi

# Étape 1: Vérification des prérequis
log_info "Étape 1/7: Vérification des prérequis..."
echo ""

MISSING=0
check_requirement "docker" || MISSING=$((MISSING + 1))
check_requirement "docker-compose" || MISSING=$((MISSING + 1))
check_requirement "git" || MISSING=$((MISSING + 1))
check_requirement "curl" || MISSING=$((MISSING + 1))

if [ $MISSING -gt 0 ]; then
    log_error "$MISSING prérequis manquants. Veuillez les installer."
    exit 1
fi

echo ""
log_success "Tous les prérequis sont installés"
echo ""

# Étape 2: Vérification du répertoire projet
log_info "Étape 2/7: Vérification du répertoire projet..."
echo ""

if [ ! -d "$PROJECT_DIR" ]; then
    log_error "Répertoire $PROJECT_DIR introuvable"
    log_info "Clonez d'abord le projet:"
    echo "  git clone https://github.com/yourusername/coucou_beaute.git $PROJECT_DIR"
    exit 1
fi

cd "$PROJECT_DIR" || exit 1
log_success "Répertoire projet: $PROJECT_DIR"
echo ""

# Étape 3: Configuration des permissions
log_info "Étape 3/7: Configuration des permissions..."
echo ""

# Scripts exécutables
for script in deploy.sh deploy-cron.sh fix-ssl-cert.sh; do
    if [ -f "$script" ]; then
        chmod +x "$script"
        log_success "$script rendu exécutable"
    else
        log_warning "$script introuvable (ignoré)"
    fi
done

echo ""

# Étape 4: Création du fichier de log
log_info "Étape 4/7: Configuration des logs..."
echo ""

if [ ! -f "$LOG_FILE" ]; then
    sudo touch "$LOG_FILE"
    sudo chown "$USER:$USER" "$LOG_FILE"
    sudo chmod 644 "$LOG_FILE"
    log_success "Fichier de log créé: $LOG_FILE"
else
    log_success "Fichier de log existe: $LOG_FILE"
fi

echo ""

# Étape 5: Configuration Cron
log_info "Étape 5/7: Configuration du cron auto-déploiement..."
echo ""

CRON_JOB="*/15 * * * * $PROJECT_DIR/deploy-cron.sh >> $LOG_FILE 2>&1"

if crontab -l 2>/dev/null | grep -q "deploy-cron.sh"; then
    log_success "Tâche cron déjà configurée"
else
    read -p "Configurer l'auto-déploiement toutes les 15 minutes? (o/N) " -n 1 -r
    echo ""
    if [[ $REPLY =~ ^[Oo]$ ]]; then
        (crontab -l 2>/dev/null; echo "$CRON_JOB") | crontab -
        log_success "Tâche cron ajoutée"
    else
        log_info "Auto-déploiement non configuré (vous pouvez le faire manuellement)"
    fi
fi

echo ""

# Étape 6: Validation Docker Compose
log_info "Étape 6/7: Validation Docker Compose..."
echo ""

if [ -f "docker-compose.prod.yml" ]; then
    log_success "docker-compose.prod.yml trouvé"
    
    # Test de syntaxe
    if docker-compose -f docker-compose.prod.yml config > /dev/null 2>&1; then
        log_success "Configuration Docker Compose valide"
    else
        log_error "Configuration Docker Compose invalide"
        docker-compose -f docker-compose.prod.yml config
        exit 1
    fi
else
    log_error "docker-compose.prod.yml introuvable"
    exit 1
fi

echo ""

# Étape 7: Validation Nginx
log_info "Étape 7/7: Validation configuration Nginx..."
echo ""

if [ -f "nginx.conf" ]; then
    log_success "nginx.conf trouvé"
else
    log_warning "nginx.conf introuvable"
fi

echo ""

# Résumé
echo -e "${GREEN}"
echo "╔════════════════════════════════════════╗"
echo "║   CONFIGURATION TERMINÉE               ║"
echo "╚════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

log_info "📋 Résumé de la configuration:"
echo ""
echo "  📂 Projet:           $PROJECT_DIR"
echo "  📝 Logs:             $LOG_FILE"
echo "  🤖 Cron:             $(crontab -l 2>/dev/null | grep -q 'deploy-cron.sh' && echo 'Configuré ✅' || echo 'Non configuré ⚠️')"
echo "  🐳 Docker:           Validé ✅"
echo ""

log_info "🚀 Prochaines étapes:"
echo ""
echo "  1. Déployer manuellement:"
echo "     sudo bash $PROJECT_DIR/deploy.sh"
echo ""
echo "  2. Vérifier les services:"
echo "     docker compose -f docker-compose.prod.yml ps"
echo ""
echo "  3. Tester le site:"
echo "     curl -k https://196.203.120.35/"
echo ""
echo "  4. Suivre les logs auto-déploiement:"
echo "     tail -f $LOG_FILE"
echo ""

log_info "📚 Documentation:"
echo "  - MOBILE_RESPONSIVE.md   (optimisations mobile)"
echo "  - CRON_AUTO_DEPLOY.md    (auto-déploiement)"
echo "  - OPTIMISATIONS_SUMMARY.md (récapitulatif complet)"
echo "  - HTTPS_SETUP.md         (configuration SSL)"
echo ""

log_success "Configuration terminée! 🎉"

