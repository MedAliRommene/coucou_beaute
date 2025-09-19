# 🔐 Script de Configuration des Secrets GitHub - Coucou Beauté
# Ce script vous guide étape par étape pour configurer les secrets GitHub

param(
    [switch]$OpenBrowser = $true
)

# Couleurs pour les messages
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Cyan = "`e[36m"
$Magenta = "`e[35m"
$Reset = "`e[0m"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = $Reset)
    Write-Host "${Color}${Message}${Reset}"
}

function Show-Step {
    param([int]$Step, [string]$Title, [string]$Description)
    Write-ColorOutput "`n🔹 ÉTAPE $Step : $Title" $Cyan
    Write-ColorOutput "   $Description" $Blue
    Write-ColorOutput "   " + ("=" * 50) $Blue
}

function Show-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ️  $Message" $Yellow
}

function Show-Success {
    param([string]$Message)
    Write-ColorOutput "✅ $Message" $Green
}

function Show-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠️  $Message" $Yellow
}

function Show-Error {
    param([string]$Message)
    Write-ColorOutput "❌ $Message" $Red
}

# Fonction pour ouvrir le navigateur
function Open-GitHubSecrets {
    $url = "https://github.com/MedAliRommene/coucou_beaute/settings/secrets/actions"
    Write-ColorOutput "`n🌐 Ouverture de GitHub Secrets..." $Cyan
    Write-ColorOutput "URL : $url" $Blue
    
    if ($OpenBrowser) {
        try {
            Start-Process $url
            Show-Success "Page GitHub ouverte dans le navigateur"
        } catch {
            Show-Warning "Impossible d'ouvrir automatiquement le navigateur"
            Write-ColorOutput "Ouvrez manuellement : $url" $Blue
        }
    }
}

# Fonction pour afficher les valeurs des secrets
function Show-SecretValues {
    Write-ColorOutput "`n📋 VALEURS À COPIER :" $Magenta
    Write-ColorOutput "=" * 50 $Magenta
    
    # SSH_PRIVATE_KEY
    Write-ColorOutput "`n1️⃣ SSH_PRIVATE_KEY :" $Cyan
    Write-ColorOutput "   (Clé privée SSH - voir le fichier GITHUB_SECRETS_CONFIG.md)" $Blue
    
    # SERVER_USER
    Write-ColorOutput "`n2️⃣ SERVER_USER :" $Cyan
    Write-ColorOutput "   vpsuser" $Green
    
    # SERVER_HOST
    Write-ColorOutput "`n3️⃣ SERVER_HOST :" $Cyan
    Write-ColorOutput "   196.203.120.35" $Green
    
    # DOCKER_USERNAME
    Write-ColorOutput "`n4️⃣ DOCKER_USERNAME :" $Cyan
    Write-ColorOutput "   coucoubeaute" $Green
    
    # DOCKER_PASSWORD
    Write-ColorOutput "`n5️⃣ DOCKER_PASSWORD :" $Cyan
    Write-ColorOutput "   [Votre token Docker Hub - à récupérer sur hub.docker.com]" $Yellow
}

# Fonction pour afficher les instructions détaillées
function Show-DetailedInstructions {
    Write-ColorOutput "`n📖 INSTRUCTIONS DÉTAILLÉES :" $Magenta
    Write-ColorOutput "=" * 50 $Magenta
    
    Write-ColorOutput "`n🔹 Pour chaque secret :" $Cyan
    Write-ColorOutput "   1. Cliquez sur 'New repository secret'" $Blue
    Write-ColorOutput "   2. Entrez le nom du secret (ex: SSH_PRIVATE_KEY)" $Blue
    Write-ColorOutput "   3. Copiez-collez la valeur correspondante" $Blue
    Write-ColorOutput "   4. Cliquez sur 'Add secret'" $Blue
    
    Write-ColorOutput "`n🔹 Ordre recommandé :" $Cyan
    Write-ColorOutput "   1. SSH_PRIVATE_KEY (le plus important)" $Green
    Write-ColorOutput "   2. SERVER_USER" $Green
    Write-ColorOutput "   3. SERVER_HOST" $Green
    Write-ColorOutput "   4. DOCKER_USERNAME" $Green
    Write-ColorOutput "   5. DOCKER_PASSWORD" $Green
}

# Fonction pour vérifier la configuration
function Test-Configuration {
    Write-ColorOutput "`n🧪 VÉRIFICATION DE LA CONFIGURATION :" $Magenta
    Write-ColorOutput "=" * 50 $Magenta
    
    Write-ColorOutput "`nAprès avoir configuré tous les secrets :" $Cyan
    Write-ColorOutput "1. Faites un commit et push :" $Blue
    Write-ColorOutput "   git add ." $Green
    Write-ColorOutput "   git commit -m 'feat: configure GitHub secrets'" $Green
    Write-ColorOutput "   git push origin main" $Green
    
    Write-ColorOutput "`n2. Vérifiez le déploiement :" $Blue
    Write-ColorOutput "   - Allez dans l'onglet 'Actions' de votre repository" $Green
    Write-ColorOutput "   - Surveillez le workflow 'Deploy to Production'" $Green
    Write-ColorOutput "   - Vérifiez que toutes les étapes passent" $Green
}

# Fonction principale
function Start-Configuration {
    Write-ColorOutput "🔐 CONFIGURATION DES SECRETS GITHUB - COUCOU BEAUTÉ" $Magenta
    Write-ColorOutput "=" * 60 $Magenta
    Write-ColorOutput "Ce script vous guide pour configurer les secrets GitHub nécessaires au déploiement automatique." $Blue
    Write-ColorOutput ""
    
    # Étape 1 : Introduction
    Show-Step 1 "Introduction" "Préparation de la configuration des secrets GitHub"
    Show-Info "Vous allez configurer 5 secrets GitHub pour permettre le déploiement automatique"
    Show-Info "Temps estimé : 5-10 minutes"
    
    # Étape 2 : Accès à GitHub
    Show-Step 2 "Accès à GitHub" "Ouvrir la page des secrets GitHub"
    Show-Info "Nous allons ouvrir la page des secrets de votre repository"
    Open-GitHubSecrets
    
    # Étape 3 : Valeurs des secrets
    Show-Step 3 "Valeurs des Secrets" "Afficher les valeurs à copier"
    Show-SecretValues
    
    # Étape 4 : Instructions détaillées
    Show-Step 4 "Instructions Détaillées" "Comment ajouter chaque secret"
    Show-DetailedInstructions
    
    # Étape 5 : Vérification
    Show-Step 5 "Vérification" "Tester la configuration"
    Test-Configuration
    
    # Résumé final
    Write-ColorOutput "`n🎉 CONFIGURATION TERMINÉE !" $Green
    Write-ColorOutput "=" * 50 $Green
    Write-ColorOutput "Vous avez maintenant toutes les informations nécessaires pour configurer les secrets GitHub." $Blue
    Write-ColorOutput "Une fois configurés, votre déploiement automatique fonctionnera !" $Blue
    
    Write-ColorOutput "`n📁 Fichiers créés :" $Cyan
    Write-ColorOutput "   - GITHUB_SECRETS_CONFIG.md : Valeurs des secrets" $Blue
    Write-ColorOutput "   - configure-github-secrets.ps1 : Ce script" $Blue
    Write-ColorOutput "   - setup-ssh-server.sh : Configuration du serveur" $Blue
    Write-ColorOutput "   - test-ssh-connection.ps1 : Test de connexion SSH" $Blue
    
    Write-ColorOutput "`n🚀 Prochaines étapes :" $Cyan
    Write-ColorOutput "   1. Configurez les secrets sur GitHub" $Green
    Write-ColorOutput "   2. Commitez et poussez les changements" $Green
    Write-ColorOutput "   3. Surveillez le déploiement dans GitHub Actions" $Green
    Write-ColorOutput "   4. Vérifiez que votre site est accessible" $Green
}

# Lancer la configuration
Start-Configuration
