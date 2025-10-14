# Script PowerShell pour configurer HTTPS
Write-Host "🔒 Configuration HTTPS pour Coucou Beauté" -ForegroundColor Cyan

# 1. Copier les fichiers de configuration sur le serveur
Write-Host "📤 Copie des fichiers de configuration..." -ForegroundColor Yellow
scp nginx.conf vpsuser@196.203.120.35:/opt/coucou_beaute/
scp setup-https.sh vpsuser@196.203.120.35:/opt/coucou_beaute/

# 2. Exécuter la configuration HTTPS
Write-Host "🔧 Exécution de la configuration HTTPS..." -ForegroundColor Yellow
ssh vpsuser@196.203.120.35 "cd /opt/coucou_beaute && chmod +x setup-https.sh && ./setup-https.sh"

Write-Host "✅ Configuration HTTPS terminée!" -ForegroundColor Green
Write-Host "🌐 Votre site est maintenant accessible sur https://196.203.120.35" -ForegroundColor Green
