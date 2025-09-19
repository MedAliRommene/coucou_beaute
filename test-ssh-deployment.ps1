# 🔍 Script de Test SSH pour Déploiement - Coucou Beauté
# Ce script teste la connexion SSH avec les mêmes paramètres que GitHub Actions

param(
    [string]$ServerHost = "196.203.120.35",
    [string]$ServerUser = "vpsuser",
    [int]$Port = 22,
    [int]$MaxAttempts = 3,
    [int]$InitialDelay = 10
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

function Test-NetworkConnectivity {
    param([string]$Host, [int]$Port)
    
    Write-ColorOutput "`n🌐 Test de connectivité réseau vers $Host..." $Cyan
    
    # Test de ping
    Write-ColorOutput "1️⃣ Test de ping..." $Yellow
    try {
        $pingResult = Test-Connection -ComputerName $Host -Count 3 -Quiet
        if ($pingResult) {
            Write-ColorOutput "✅ Ping réussi vers $Host" $Green
        } else {
            Write-ColorOutput "❌ Ping échoué vers $Host" $Red
            return $false
        }
    } catch {
        Write-ColorOutput "❌ Erreur lors du test ping : $($_.Exception.Message)" $Red
        return $false
    }
    
    # Test du port
    Write-ColorOutput "2️⃣ Test du port $Port..." $Yellow
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connectTask = $tcpClient.ConnectAsync($Host, $Port)
        $timeoutTask = Start-Sleep -Seconds 10 -PassThru
        
        $completed = $connectTask.Wait(10000) # 10 secondes timeout
        
        if ($completed -and $tcpClient.Connected) {
            Write-ColorOutput "✅ Port $Port accessible sur $Host" $Green
            $tcpClient.Close()
            return $true
        } else {
            Write-ColorOutput "❌ Port $Port non accessible sur $Host" $Red
            return $false
        }
    } catch {
        Write-ColorOutput "❌ Erreur lors du test du port : $($_.Exception.Message)" $Red
        return $false
    }
}

function Test-SSHConnection {
    param([string]$Host, [string]$User, [int]$MaxAttempts, [int]$InitialDelay)
    
    Write-ColorOutput "`n🔍 Test de connexion SSH vers $User@$Host..." $Cyan
    
    # Vérifier si OpenSSH est disponible
    $sshPath = Get-Command ssh -ErrorAction SilentlyContinue
    if (-not $sshPath) {
        Write-ColorOutput "❌ OpenSSH non installé sur cette machine" $Red
        Write-ColorOutput "   Installez OpenSSH ou utilisez PuTTY pour tester" $Yellow
        return $false
    }
    
    $delay = $InitialDelay
    
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        Write-ColorOutput "`n🔄 Tentative $attempt/$MaxAttempts..." $Yellow
        
        # Paramètres SSH identiques à GitHub Actions
        $sshCommand = "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 -o ServerAliveInterval=10 -o ServerAliveCountMax=3 -o BatchMode=yes $User@$Host 'echo \"SSH connection successful\"'"
        
        Write-ColorOutput "Commande : $sshCommand" $Blue
        
        try {
            $result = Invoke-Expression $sshCommand 2>&1
            $exitCode = $LASTEXITCODE
            
            if ($exitCode -eq 0) {
                Write-ColorOutput "✅ Connexion SSH réussie à la tentative $attempt" $Green
                Write-ColorOutput "Réponse du serveur : $result" $Green
                return $true
            } else {
                Write-ColorOutput "❌ Échec de la tentative $attempt (code: $exitCode)" $Red
                Write-ColorOutput "Message d'erreur : $result" $Red
                
                if ($attempt -lt $MaxAttempts) {
                    Write-ColorOutput "⏳ Attente de ${delay}s avant la prochaine tentative..." $Yellow
                    Start-Sleep -Seconds $delay
                    $delay = $delay * 2  # Augmenter le délai exponentiellement
                }
            }
        } catch {
            Write-ColorOutput "❌ Erreur lors de la tentative $attempt : $($_.Exception.Message)" $Red
            
            if ($attempt -lt $MaxAttempts) {
                Write-ColorOutput "⏳ Attente de ${delay}s avant la prochaine tentative..." $Yellow
                Start-Sleep -Seconds $delay
                $delay = $delay * 2
            }
        }
    }
    
    Write-ColorOutput "❌ Toutes les tentatives de connexion SSH ont échoué" $Red
    return $false
}

function Show-DiagnosticInfo {
    param([string]$Host, [string]$User)
    
    Write-ColorOutput "`n📊 Informations de diagnostic :" $Magenta
    Write-ColorOutput "=" * 50 $Magenta
    Write-ColorOutput "Serveur : $Host" $Blue
    Write-ColorOutput "Utilisateur : $User" $Blue
    Write-ColorOutput "Port : 22" $Blue
    Write-ColorOutput "Tentatives max : $MaxAttempts" $Blue
    Write-ColorOutput "Délai initial : ${InitialDelay}s" $Blue
    Write-ColorOutput ""
    
    Write-ColorOutput "🔧 Paramètres SSH utilisés :" $Cyan
    Write-ColorOutput "   - StrictHostKeyChecking=no" $Blue
    Write-ColorOutput "   - ConnectTimeout=30" $Blue
    Write-ColorOutput "   - ServerAliveInterval=10" $Blue
    Write-ColorOutput "   - ServerAliveCountMax=3" $Blue
    Write-ColorOutput "   - BatchMode=yes" $Blue
}

function Show-TroubleshootingTips {
    Write-ColorOutput "`n🛠️ Conseils de dépannage :" $Magenta
    Write-ColorOutput "=" * 50 $Magenta
    
    Write-ColorOutput "Si la connexion SSH échoue :" $Yellow
    Write-ColorOutput "1. Vérifiez que l'utilisateur '$ServerUser' existe sur le serveur" $Blue
    Write-ColorOutput "2. Vérifiez que votre clé publique SSH est dans ~/.ssh/authorized_keys" $Blue
    Write-ColorOutput "3. Vérifiez les permissions :" $Blue
    Write-ColorOutput "   chmod 700 ~/.ssh" $Green
    Write-ColorOutput "   chmod 600 ~/.ssh/authorized_keys" $Green
    Write-ColorOutput "4. Vérifiez la configuration SSH : sudo nano /etc/ssh/sshd_config" $Blue
    Write-ColorOutput "5. Redémarrez SSH : sudo systemctl restart ssh" $Blue
    Write-ColorOutput "6. Vérifiez les logs SSH : sudo journalctl -u ssh" $Blue
    Write-ColorOutput ""
    
    Write-ColorOutput "Pour configurer le serveur :" $Yellow
    Write-ColorOutput "1. Exécutez le script setup-ssh-server.sh sur le serveur" $Blue
    Write-ColorOutput "2. Ajoutez votre clé publique : ssh-copy-id $ServerUser@$ServerHost" $Blue
    Write-ColorOutput "3. Testez : ssh $ServerUser@$ServerHost" $Blue
}

# Fonction principale
function Start-SSHTest {
    Write-ColorOutput "🔍 Test SSH pour Déploiement - Coucou Beauté" $Magenta
    Write-ColorOutput "=" * 60 $Magenta
    Write-ColorOutput "Ce script teste la connexion SSH avec les mêmes paramètres que GitHub Actions" $Blue
    Write-ColorOutput ""
    
    # Test de connectivité réseau
    if (-not (Test-NetworkConnectivity -Host $ServerHost -Port $Port)) {
        Write-ColorOutput "❌ Test de connectivité réseau échoué" $Red
        Show-TroubleshootingTips
        exit 1
    }
    
    # Test de connexion SSH
    if (Test-SSHConnection -Host $ServerHost -User $ServerUser -MaxAttempts $MaxAttempts -InitialDelay $InitialDelay) {
        Write-ColorOutput "`n🎉 Test SSH réussi !" $Green
        Write-ColorOutput "Votre configuration SSH est prête pour le déploiement GitHub Actions" $Green
    } else {
        Write-ColorOutput "`n❌ Test SSH échoué" $Red
        Show-DiagnosticInfo -Host $ServerHost -User $ServerUser
        Show-TroubleshootingTips
        exit 1
    }
    
    Write-ColorOutput "`n📋 Prochaines étapes :" $Cyan
    Write-ColorOutput "1. Commitez et poussez vos changements" $Green
    Write-ColorOutput "2. Surveillez le déploiement dans GitHub Actions" $Green
    Write-ColorOutput "3. Vérifiez que votre site est accessible" $Green
}

# Lancer le test
Start-SSHTest
