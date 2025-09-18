#!/bin/bash
# ===========================================
# CONFIGURATION SERVEUR - Coucou Beauté
# ===========================================
# Serveur: 196.203.120.35
# Utilisateur: root (ou ubuntu selon votre configuration)

set -e

echo "🚀 Configuration du serveur 196.203.120.35 pour Coucou Beauté..."

# ===========================================
# 1. MISE À JOUR DU SYSTÈME
# ===========================================
echo "📦 Mise à jour du système..."
apt update && apt upgrade -y

# ===========================================
# 2. INSTALLATION DOCKER
# ===========================================
echo "🐳 Installation de Docker..."
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    usermod -aG docker $USER
    rm get-docker.sh
    echo "✅ Docker installé"
else
    echo "✅ Docker déjà installé"
fi

# ===========================================
# 3. INSTALLATION DOCKER COMPOSE
# ===========================================
echo "🐳 Installation de Docker Compose..."
if ! command -v docker-compose &> /dev/null; then
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    echo "✅ Docker Compose installé"
else
    echo "✅ Docker Compose déjà installé"
fi

# ===========================================
# 4. INSTALLATION GIT
# ===========================================
echo "📥 Installation de Git..."
if ! command -v git &> /dev/null; then
    apt install git -y
    echo "✅ Git installé"
else
    echo "✅ Git déjà installé"
fi

# ===========================================
# 5. INSTALLATION NGINX
# ===========================================
echo "🌐 Installation de Nginx..."
if ! command -v nginx &> /dev/null; then
    apt install nginx -y
    systemctl enable nginx
    systemctl start nginx
    echo "✅ Nginx installé"
else
    echo "✅ Nginx déjà installé"
fi

# ===========================================
# 6. CONFIGURATION DU RÉPERTOIRE
# ===========================================
echo "📁 Configuration du répertoire de travail..."
mkdir -p /opt/coucou_beaute
cd /opt/coucou_beaute

# ===========================================
# 7. CLONAGE DU REPOSITORY
# ===========================================
echo "📥 Clonage du repository..."
if [ ! -d ".git" ]; then
    git clone https://github.com/MedAliRommene/coucou_beaute.git .
    echo "✅ Repository cloné"
else
    echo "✅ Repository déjà présent"
    git pull origin main
fi

# ===========================================
# 8. CONFIGURATION DE L'ENVIRONNEMENT
# ===========================================
echo "⚙️ Configuration de l'environnement de production..."
if [ ! -f "backend/.env" ]; then
    cp backend/env.example backend/.env
    echo "📝 Fichier .env créé à partir de env.example"
    echo "⚠️  IMPORTANT: Configurez votre fichier backend/.env !"
    echo "   nano backend/.env"
else
    echo "✅ Fichier .env déjà présent"
fi

# ===========================================
# 9. CONFIGURATION NGINX
# ===========================================
echo "🌐 Configuration de Nginx..."
cat > /etc/nginx/sites-available/coucou_beaute << 'EOF'
server {
    listen 80;
    server_name 196.203.120.35 coucoubeauty.com;

    client_max_body_size 25m;

    location /static/ {
        alias /var/www/static/;
        access_log off;
        expires 30d;
    }
    
    location /media/ {
        alias /var/www/media/;
        access_log off;
        expires 30d;
    }

    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://localhost:8000;
        proxy_read_timeout 60s;
    }
}
EOF

# Activer le site
ln -sf /etc/nginx/sites-available/coucou_beaute /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

echo "✅ Nginx configuré"

# ===========================================
# 10. CONFIGURATION DES PERMISSIONS
# ===========================================
echo "🔐 Configuration des permissions..."
chown -R www-data:www-data /opt/coucou_beaute
chmod -R 755 /opt/coucou_beaute

# ===========================================
# 11. CONFIGURATION DU FIREWALL
# ===========================================
echo "🔥 Configuration du firewall..."
ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable

echo "✅ Firewall configuré"

# ===========================================
# 12. CRÉATION DU SCRIPT DE DÉPLOIEMENT
# ===========================================
echo "📝 Création du script de déploiement..."
cat > /opt/coucou_beaute/deploy.sh << 'EOF'
#!/bin/bash
cd /opt/coucou_beaute

# Sauvegarder l'ancien .env
if [ -f backend/.env ]; then
    cp backend/.env backend/.env.backup.$(date +%s)
fi

# Récupérer les dernières modifications
git pull origin main

# Redémarrer les services
docker compose -f docker-compose.prod.yml down
docker compose -f docker-compose.prod.yml up -d

# Vérifier le déploiement
sleep 30
if curl -f http://localhost:80 > /dev/null 2>&1; then
    echo "✅ Déploiement réussi !"
else
    echo "❌ Problème de déploiement"
    docker compose -f docker-compose.prod.yml logs
    exit 1
fi
EOF

chmod +x /opt/coucou_beaute/deploy.sh

echo "✅ Script de déploiement créé"

# ===========================================
# 13. INSTRUCTIONS FINALES
# ===========================================
echo ""
echo "🎉 Configuration du serveur terminée !"
echo ""
echo "📋 Prochaines étapes :"
echo ""
echo "1. 🔧 Configurez votre fichier .env :"
echo "   nano /opt/coucou_beaute/backend/.env"
echo ""
echo "2. 🚀 Déployez l'application :"
echo "   cd /opt/coucou_beaute"
echo "   ./deploy.sh"
echo ""
echo "3. 🔐 Configurez les secrets GitHub :"
echo "   - Allez sur votre repository GitHub"
echo "   - Settings > Secrets and variables > Actions"
echo "   - Ajoutez les secrets listés dans .github/SECRETS.md"
echo ""
echo "4. 🧪 Testez le CI/CD :"
echo "   - Faites un commit sur GitHub"
echo "   - Vérifiez que le déploiement se lance automatiquement"
echo ""
echo "📚 Documentation complète dans /opt/coucou_beaute/DEPLOYMENT.md"
echo "🔧 Configuration des secrets dans /opt/coucou_beaute/.github/SECRETS.md"
echo ""
echo "✅ Configuration terminée !"
