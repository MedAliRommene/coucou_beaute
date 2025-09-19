#!/bin/bash
# ===========================================
# SCRIPT DE NETTOYAGE SERVEUR - Coucou Beauté
# ===========================================

VPS_HOST="196.203.120.35"
VPS_USER="vpsuser"
SSH_KEY="C:/Users/Lenovo/.ssh/coucou_beaute_rsa_pem"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}===========================================${NC}"
echo -e "${CYAN}NETTOYAGE COMPLET DU SERVEUR${NC}"
echo -e "${CYAN}===========================================${NC}"

# 1. Test de connectivité
echo -e "${BLUE}Test de connectivité au serveur...${NC}"
if ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" "echo 'SSH OK'" > /dev/null 2>&1; then
    echo -e "${GREEN}Serveur accessible via SSH${NC}"
else
    echo -e "${RED}Serveur non accessible via SSH${NC}"
    exit 1
fi

# 2. Nettoyage complet du serveur
echo -e "${YELLOW}Nettoyage complet du serveur...${NC}"
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" << 'EOF'
    echo "=== Arrêt de tous les services Docker ==="
    docker compose -f /opt/coucou_beaute/docker-compose.prod.yml down || true
    docker stop $(docker ps -aq) || true
    docker rm $(docker ps -aq) || true
    
    echo "=== Suppression de toutes les images Docker ==="
    docker rmi $(docker images -aq) || true
    docker system prune -af || true
    
    echo "=== Suppression du répertoire /opt/coucou_beaute ==="
    sudo rm -rf /opt/coucou_beaute
    
    echo "=== Suppression du répertoire github-runner ==="
    sudo rm -rf /opt/github-runner
    
    echo "=== Nettoyage des fichiers temporaires ==="
    sudo rm -rf /tmp/coucou_beaute*
    sudo rm -rf /home/vpsuser/coucou_beaute*
    
    echo "=== Vérification de l'espace disque ==="
    df -h
    
    echo "=== Nettoyage terminé ==="
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}Nettoyage du serveur terminé avec succès${NC}"
else
    echo -e "${RED}Erreur lors du nettoyage du serveur${NC}"
    exit 1
fi

echo -e "${GREEN}===========================================${NC}"
echo -e "${GREEN}NETTOYAGE TERMINÉ !${NC}"
echo -e "${GREEN}Le serveur est maintenant propre et prêt pour un nouveau déploiement${NC}"
echo -e "${GREEN}===========================================${NC}"
