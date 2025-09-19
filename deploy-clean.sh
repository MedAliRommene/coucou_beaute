#!/bin/bash
# ===========================================
# SCRIPT DE DÉPLOIEMENT PROPRE - Coucou Beauté
# ===========================================

VPS_HOST="196.203.120.35"
VPS_USER="vpsuser"
SSH_KEY="C:/Users/Lenovo/.ssh/coucou_beaute_rsa_pem"
PROJECT_DIR="/opt/coucou_beaute"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# Fonction pour afficher les messages
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

echo -e "${CYAN}===========================================${NC}"
echo -e "${CYAN}DÉPLOIEMENT PROPRE - COUCOU BEAUTÉ${NC}"
echo -e "${CYAN}===========================================${NC}"

# 1. Test de connectivité
print_message $BLUE "Test de connectivité au serveur..."
if ssh -i "$SSH_KEY" -o ConnectTimeout=10 -o BatchMode=yes -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" "echo 'SSH OK'" > /dev/null 2>&1; then
    print_message $GREEN "Serveur accessible via SSH"
else
    print_message $RED "Serveur non accessible via SSH"
    exit 1
fi

# 2. Tests locaux
print_message $BLUE "Exécution des tests locaux..."
cd backend
if [ ! -d "venv" ]; then
    print_message $YELLOW "Création de l'environnement virtuel..."
    python -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt
    deactivate
fi

source venv/bin/activate
python manage.py check --deploy
if [ $? -ne 0 ]; then
    print_message $RED "Tests locaux échoués"
    deactivate
    exit 1
fi
deactivate
cd ..
print_message $GREEN "Tests locaux réussis"

# 3. Push vers GitHub
print_message $BLUE "Poussée vers GitHub..."
git add .
git commit -m "Deploy: $(date +"%Y-%m-%d %H:%M:%S") - clean deployment"
git push origin main
if [ $? -ne 0 ]; then
    print_message $RED "Erreur lors du push vers GitHub"
    exit 1
fi
print_message $GREEN "Push Git réussi"

# 4. Préparation du serveur
print_message $YELLOW "Préparation du serveur..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" << 'EOF'
    echo "=== Création du répertoire du projet ==="
    sudo mkdir -p /opt/coucou_beaute
    sudo chown vpsuser:vpsuser /opt/coucou_beaute
    
    echo "=== Clonage du projet depuis GitHub ==="
    cd /opt/coucou_beaute
    git clone https://github.com/MedAliRommene/coucou_beaute.git .
    
    echo "=== Configuration des permissions Git ==="
    git config --global --add safe.directory /opt/coucou_beaute
    
    echo "=== Création du fichier .env de production ==="
    cp backend/env.production backend/.env
    echo "Fichier .env créé"
    
    echo "=== Vérification de Docker ==="
    docker --version
    docker compose version
EOF

if [ $? -ne 0 ]; then
    print_message $RED "Erreur lors de la préparation du serveur"
    exit 1
fi

# 5. Déploiement Docker
print_message $BLUE "Déploiement Docker..."
ssh -i "$SSH_KEY" -o StrictHostKeyChecking=no "$VPS_USER@$VPS_HOST" << 'EOF'
    cd /opt/coucou_beaute
    
    echo "=== Démarrage des services Docker ==="
    docker compose -f docker-compose.prod.yml up -d --build
    
    echo "=== Attente du démarrage des services ==="
    sleep 30
    
    echo "=== Exécution des migrations ==="
    docker compose -f docker-compose.prod.yml exec web python manage.py migrate --noinput
    
    echo "=== Collecte des fichiers statiques ==="
    docker compose -f docker-compose.prod.yml exec web python manage.py collectstatic --noinput
    
    echo "=== Vérification du déploiement ==="
    if curl -f http://localhost:80 > /dev/null 2>&1; then
        echo "✅ Déploiement réussi !"
        docker compose -f docker-compose.prod.yml ps
    else
        echo "❌ Problème de déploiement"
        docker compose -f docker-compose.prod.yml logs
        exit 1
    fi
EOF

if [ $? -eq 0 ]; then
    print_message $GREEN "==========================================="
    print_message $GREEN "DÉPLOIEMENT RÉUSSI !"
    print_message $GREEN "Votre site est accessible sur http://$VPS_HOST"
    print_message $GREEN "==========================================="
else
    print_message $RED "Déploiement échoué"
    exit 1
fi
