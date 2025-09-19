#!/bin/bash

# 🔐 Script de Configuration SSH pour Coucou Beauté
# Ce script configure SSH sur le serveur pour permettre le déploiement GitHub Actions

set -e

echo "🔧 Configuration SSH pour Coucou Beauté..."

# Couleurs pour les messages
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Vérifier si le script est exécuté en tant que root
if [ "$EUID" -ne 0 ]; then
    log_error "Ce script doit être exécuté en tant que root"
    exit 1
fi

# 1. Mettre à jour le système
log_info "Mise à jour du système..."
apt update && apt upgrade -y

# 2. Installer OpenSSH Server s'il n'est pas installé
log_info "Installation d'OpenSSH Server..."
apt install -y openssh-server

# 3. Créer l'utilisateur vpsuser s'il n'existe pas
if ! id "vpsuser" &>/dev/null; then
    log_info "Création de l'utilisateur vpsuser..."
    useradd -m -s /bin/bash vpsuser
    usermod -aG sudo vpsuser
    log_warn "Mot de passe pour vpsuser (changez-le après) :"
    passwd vpsuser
else
    log_info "L'utilisateur vpsuser existe déjà"
fi

# 4. Créer le répertoire .ssh pour vpsuser
log_info "Configuration du répertoire SSH pour vpsuser..."
mkdir -p /home/vpsuser/.ssh
chmod 700 /home/vpsuser/.ssh
chown vpsuser:vpsuser /home/vpsuser/.ssh

# 5. Configurer SSH pour permettre l'authentification par clé
log_info "Configuration d'OpenSSH..."
cat > /etc/ssh/sshd_config << 'EOF'
# Configuration SSH pour Coucou Beauté
Port 22
Protocol 2
HostKey /etc/ssh/ssh_host_rsa_key
HostKey /etc/ssh/ssh_host_ecdsa_key
HostKey /etc/ssh/ssh_host_ed25519_key

# Authentification
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
PasswordAuthentication yes
PermitEmptyPasswords no
ChallengeResponseAuthentication no

# Configuration de sécurité
PermitRootLogin yes
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 60
ClientAliveCountMax 3

# Logging
SyslogFacility AUTH
LogLevel INFO

# Configuration des utilisateurs
AllowUsers root vpsuser ubuntu

# Désactiver X11 forwarding
X11Forwarding no
X11DisplayOffset 10
PrintMotd no
PrintLastLog yes
TCPKeepAlive yes

# Configuration des sous-systèmes
Subsystem sftp /usr/lib/openssh/sftp-server
EOF

# 6. Redémarrer le service SSH
log_info "Redémarrage du service SSH..."
systemctl restart ssh
systemctl enable ssh

# 7. Configurer le firewall
log_info "Configuration du firewall..."
ufw allow ssh
ufw --force enable

# 8. Créer le répertoire du projet
log_info "Création du répertoire du projet..."
mkdir -p /opt/coucou_beaute
chown vpsuser:vpsuser /opt/coucou_beaute

# 9. Installer Docker et Docker Compose
log_info "Installation de Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sh get-docker.sh
usermod -aG docker vpsuser

log_info "Installation de Docker Compose..."
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# 10. Installer Git
log_info "Installation de Git..."
apt install -y git

# 11. Configuration finale
log_info "Configuration finale..."
echo "✅ Configuration SSH terminée !"
echo ""
echo "📋 Prochaines étapes :"
echo "1. Ajoutez votre clé publique SSH à /home/vpsuser/.ssh/authorized_keys"
echo "2. Testez la connexion : ssh vpsuser@$(curl -s ifconfig.me)"
echo "3. Configurez les secrets GitHub :"
echo "   - SSH_PRIVATE_KEY : Votre clé privée"
echo "   - SERVER_USER : vpsuser"
echo "   - SERVER_HOST : $(curl -s ifconfig.me)"
echo ""
echo "🔑 Pour ajouter votre clé SSH :"
echo "ssh-copy-id vpsuser@$(curl -s ifconfig.me)"
echo ""
echo "🧪 Test de connexion :"
echo "ssh vpsuser@$(curl -s ifconfig.me) 'echo \"Connexion SSH réussie !\"'"

log_info "Configuration terminée avec succès !"
