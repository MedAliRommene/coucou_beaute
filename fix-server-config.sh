#!/bin/bash

# 🔧 Script de Correction de la Configuration du Serveur - Coucou Beauté
# Ce script corrige les problèmes de configuration du serveur

set -e

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Fonction pour afficher les messages
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Vérifier si le script est exécuté en tant que root
if [ "$EUID" -ne 0 ]; then
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

log_info "🔧 Correction de la configuration du serveur Coucou Beauté..."

# 1. Vérifier l'état des services
log_info "1️⃣ Vérification de l'état des services..."

# Vérifier SSH
if systemctl is-active --quiet ssh; then
    log_info "✅ Service SSH actif"
else
    log_warn "❌ Service SSH inactif - Démarrage..."
    systemctl start ssh
    systemctl enable ssh
fi

# Vérifier Docker
if systemctl is-active --quiet docker; then
    log_info "✅ Service Docker actif"
else
    log_warn "❌ Service Docker inactif - Démarrage..."
    systemctl start docker
    systemctl enable docker
fi

# 2. Vérifier la configuration SSH
log_info "2️⃣ Vérification de la configuration SSH..."

# Vérifier que SSH écoute sur le port 22
if netstat -tlnp | grep -q ":22 "; then
    log_info "✅ SSH écoute sur le port 22"
else
    log_warn "❌ SSH n'écoute pas sur le port 22"
    log_info "Redémarrage du service SSH..."
    systemctl restart ssh
    sleep 5
    if netstat -tlnp | grep -q ":22 "; then
        log_info "✅ SSH écoute maintenant sur le port 22"
    else
        log_error "❌ SSH ne peut pas démarrer sur le port 22"
    fi
fi

# 3. Vérifier le firewall
log_info "3️⃣ Vérification du firewall..."

# Vérifier UFW
if ufw status | grep -q "Status: active"; then
    log_info "✅ UFW actif"
    if ufw status | grep -q "22/tcp"; then
        log_info "✅ Port 22 autorisé dans UFW"
    else
        log_warn "❌ Port 22 non autorisé dans UFW - Ajout..."
        ufw allow ssh
        ufw allow 22/tcp
    fi
else
    log_warn "⚠️  UFW inactif"
fi

# 4. Vérifier la configuration Docker
log_info "4️⃣ Vérification de la configuration Docker..."

# Vérifier que Docker fonctionne
if docker --version >/dev/null 2>&1; then
    log_info "✅ Docker installé et fonctionnel"
else
    log_error "❌ Docker non installé ou non fonctionnel"
    exit 1
fi

# Vérifier Docker Compose
if docker compose version >/dev/null 2>&1; then
    log_info "✅ Docker Compose installé et fonctionnel"
else
    log_error "❌ Docker Compose non installé ou non fonctionnel"
    exit 1
fi

# 5. Vérifier la configuration réseau
log_info "5️⃣ Vérification de la configuration réseau..."

# Vérifier les interfaces réseau
log_debug "Interfaces réseau disponibles :"
ip addr show | grep -E "inet [0-9]" | while read line; do
    log_debug "  $line"
done

# Vérifier la connectivité sortante
if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
    log_info "✅ Connectivité sortante fonctionnelle"
else
    log_warn "❌ Problème de connectivité sortante"
fi

# 6. Vérifier les utilisateurs
log_info "6️⃣ Vérification des utilisateurs..."

# Vérifier que vpsuser existe
if id "vpsuser" >/dev/null 2>&1; then
    log_info "✅ Utilisateur vpsuser existe"
    
    # Vérifier les permissions SSH
    if [ -d "/home/vpsuser/.ssh" ]; then
        log_info "✅ Répertoire .ssh existe pour vpsuser"
        
        # Vérifier les permissions
        if [ "$(stat -c %a /home/vpsuser/.ssh)" = "700" ]; then
            log_info "✅ Permissions correctes pour .ssh (700)"
        else
            log_warn "❌ Permissions incorrectes pour .ssh - Correction..."
            chmod 700 /home/vpsuser/.ssh
        fi
        
        if [ -f "/home/vpsuser/.ssh/authorized_keys" ]; then
            log_info "✅ Fichier authorized_keys existe"
            if [ "$(stat -c %a /home/vpsuser/.ssh/authorized_keys)" = "600" ]; then
                log_info "✅ Permissions correctes pour authorized_keys (600)"
            else
                log_warn "❌ Permissions incorrectes pour authorized_keys - Correction..."
                chmod 600 /home/vpsuser/.ssh/authorized_keys
            fi
        else
            log_warn "❌ Fichier authorized_keys manquant"
        fi
    else
        log_warn "❌ Répertoire .ssh manquant pour vpsuser"
        mkdir -p /home/vpsuser/.ssh
        chmod 700 /home/vpsuser/.ssh
        chown vpsuser:vpsuser /home/vpsuser/.ssh
    fi
else
    log_error "❌ Utilisateur vpsuser n'existe pas"
    log_info "Création de l'utilisateur vpsuser..."
    useradd -m -s /bin/bash vpsuser
    usermod -aG sudo vpsuser
    usermod -aG docker vpsuser
fi

# 7. Vérifier la configuration du projet
log_info "7️⃣ Vérification de la configuration du projet..."

if [ -d "/opt/coucou_beaute" ]; then
    log_info "✅ Répertoire du projet existe"
    
    # Vérifier les permissions
    if [ "$(stat -c %U /opt/coucou_beaute)" = "vpsuser" ]; then
        log_info "✅ Permissions correctes pour le répertoire du projet"
    else
        log_warn "❌ Permissions incorrectes - Correction..."
        chown -R vpsuser:vpsuser /opt/coucou_beaute
    fi
else
    log_warn "❌ Répertoire du projet manquant"
    mkdir -p /opt/coucou_beaute
    chown vpsuser:vpsuser /opt/coucou_beaute
fi

# 8. Test de connectivité SSH
log_info "8️⃣ Test de connectivité SSH..."

# Test local
if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 -o BatchMode=yes vpsuser@localhost 'echo "SSH local test successful"' >/dev/null 2>&1; then
    log_info "✅ Test SSH local réussi"
else
    log_warn "❌ Test SSH local échoué"
fi

# 9. Redémarrage des services
log_info "9️⃣ Redémarrage des services..."

systemctl restart ssh
systemctl restart docker

# Attendre que les services soient prêts
sleep 5

# 10. Test final
log_info "🔟 Test final de connectivité..."

# Vérifier que SSH écoute
if netstat -tlnp | grep -q ":22 "; then
    log_info "✅ SSH écoute sur le port 22"
else
    log_error "❌ SSH n'écoute toujours pas sur le port 22"
fi

# Vérifier que Docker fonctionne
if docker ps >/dev/null 2>&1; then
    log_info "✅ Docker fonctionne correctement"
else
    log_error "❌ Docker ne fonctionne pas correctement"
fi

log_info "🎉 Configuration du serveur terminée !"
log_info ""
log_info "📋 Résumé des corrections :"
log_info "  ✅ Services SSH et Docker vérifiés et démarrés"
log_info "  ✅ Configuration du firewall vérifiée"
log_info "  ✅ Utilisateur vpsuser vérifié et configuré"
log_info "  ✅ Permissions SSH vérifiées et corrigées"
log_info "  ✅ Répertoire du projet configuré"
log_info ""
log_info "🧪 Test de connectivité :"
log_info "  ssh vpsuser@$(curl -s ifconfig.me)"
log_info ""
log_info "🚀 Le déploiement GitHub Actions devrait maintenant fonctionner !"
