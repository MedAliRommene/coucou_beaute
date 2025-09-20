#!/bin/bash
# Script de configuration du déploiement automatique

echo "🔧 Configuration du déploiement automatique pour Coucou Beauté..."

# Variables
PROJECT_DIR="/opt/coucou_beaute"
WEBHOOK_DIR="/opt/webhook"
WEBHOOK_PORT="5000"

# --- Fonctions utilitaires ---
log_info() {
    echo "[INFO] $1"
}

log_warn() {
    echo "[WARN] $1"
}

log_error() {
    echo "[ERROR] $1"
}

# --- Étape 1: Installation des dépendances ---
log_info "Installation des dépendances Python..."
sudo apt update
sudo apt install -y python3 python3-pip python3-venv

# --- Étape 2: Création du répertoire webhook ---
log_info "Création du répertoire webhook..."
sudo mkdir -p "$WEBHOOK_DIR"
sudo chown vpsuser:vpsuser "$WEBHOOK_DIR"

# --- Étape 3: Configuration du webhook ---
log_info "Configuration du webhook..."
cd "$WEBHOOK_DIR"

# Créer l'environnement virtuel
python3 -m venv venv
source venv/bin/activate

# Installer Flask
pip install flask

# Copier le script webhook
cp "$PROJECT_DIR/deploy-webhook.py" .

# Créer le fichier de configuration
cat > webhook.env << EOF
WEBHOOK_SECRET=votre_secret_webhook_ici
PROJECT_DIR=$PROJECT_DIR
EOF

# --- Étape 4: Configuration du service systemd ---
log_info "Configuration du service systemd..."
sudo tee /etc/systemd/system/coucou-webhook.service > /dev/null << EOF
[Unit]
Description=Coucou Beauté Webhook Deployer
After=network.target

[Service]
Type=simple
User=vpsuser
WorkingDirectory=$WEBHOOK_DIR
Environment=PATH=$WEBHOOK_DIR/venv/bin
ExecStart=$WEBHOOK_DIR/venv/bin/python deploy-webhook.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# --- Étape 5: Configuration du cron (alternative) ---
log_info "Configuration du cron..."
# Copier le script cron
cp "$PROJECT_DIR/deploy-cron.sh" /usr/local/bin/
chmod +x /usr/local/bin/deploy-cron.sh

# Ajouter au crontab (vérification toutes les 5 minutes)
(crontab -l 2>/dev/null; echo "*/5 * * * * /usr/local/bin/deploy-cron.sh") | crontab -

# --- Étape 6: Configuration du firewall ---
log_info "Configuration du firewall..."
sudo ufw allow $WEBHOOK_PORT/tcp

# --- Étape 7: Démarrage des services ---
log_info "Démarrage des services..."
sudo systemctl daemon-reload
sudo systemctl enable coucou-webhook
sudo systemctl start coucou-webhook

# --- Étape 8: Configuration des logs ---
log_info "Configuration des logs..."
sudo touch /var/log/coucou_beaute_deploy.log
sudo chown vpsuser:vpsuser /var/log/coucou_beaute_deploy.log

# --- Étape 9: Test ---
log_info "Test du webhook..."
sleep 5
if curl -f http://localhost:$WEBHOOK_PORT/health > /dev/null 2>&1; then
    log_info "✅ Webhook fonctionne correctement"
else
    log_warn "⚠️ Webhook ne répond pas - vérifiez les logs"
fi

log_info "✅ Configuration terminée !"
echo ""
log_info "📋 Prochaines étapes :"
log_info "1. Configurez le webhook GitHub :"
log_info "   - URL: http://$(curl -s ifconfig.me):$WEBHOOK_PORT/webhook"
log_info "   - Secret: votre_secret_webhook_ici"
log_info "   - Events: Push events"
log_info ""
log_info "2. Testez le déploiement manuel :"
log_info "   curl -X POST http://localhost:$WEBHOOK_PORT/deploy"
log_info ""
log_info "3. Vérifiez les logs :"
log_info "   tail -f /var/log/coucou_beaute_deploy.log"
log_info ""
log_info "4. Vérifiez le statut du service :"
log_info "   sudo systemctl status coucou-webhook"
