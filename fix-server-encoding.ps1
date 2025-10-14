# Script PowerShell pour corriger l'encodage sur le serveur
Write-Host "🔧 Correction de l'encodage sur le serveur..." -ForegroundColor Cyan

# 1. Rendre le script exécutable et le copier sur le serveur
Write-Host "📤 Copie du script de correction sur le serveur..." -ForegroundColor Yellow
scp fix-encoding-server.sh vpsuser@196.203.120.35:/opt/coucou_beaute/

# 2. Exécuter le script de correction
Write-Host "🔧 Exécution de la correction d'encodage..." -ForegroundColor Yellow
ssh vpsuser@196.203.120.35 "cd /opt/coucou_beaute && chmod +x fix-encoding-server.sh && ./fix-encoding-server.sh"

# 3. Redéployer avec le script corrigé
Write-Host "🚀 Redéploiement avec collectstatic corrigé..." -ForegroundColor Yellow
ssh vpsuser@196.203.120.35 "cd /opt/coucou_beaute && ./deploy-simple.sh"

Write-Host "✅ Correction terminée!" -ForegroundColor Green
Write-Host "🌐 Votre site devrait maintenant être accessible sur http://196.203.120.35" -ForegroundColor Green
