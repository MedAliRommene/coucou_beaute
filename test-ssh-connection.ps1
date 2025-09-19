# 🔍 Script de Test de Connexion SSH - Coucou Beauté
# Ce script teste la connexion SSH vers votre serveur

param(
    [string]$ServerHost = "196.203.120.35",
    [string]$ServerUser = "vpsuser",
    [int]$Port = 22,
    [int]$Timeout = 30
)

# Couleurs pour les messages
$Red = "`e[31m"
$Green = "`e[32m"
$Yellow = "`e[33m"
$Blue = "`e[34m"
$Reset = "`e[0m"

function Write-ColorOutput {
    param([string]$Message, [string]$Color = $Reset)
    Write-Host "${Color}${Message}${Reset}"
}

Write-ColorOutput "🔍 Test de Connexion SSH - Coucou Beauté" $Blue
Write-ColorOutput "=========================================" $Blue
Write-ColorOutput ""

# 1. Test de ping
Write-ColorOutput "1️⃣ Test de connectivité réseau..." $Yellow
try {
    $pingResult = Test-Connection -ComputerName $ServerHost -Count 4 -Quiet
    if ($pingResult) {
        Write-ColorOutput "✅ Serveur accessible via ping" $Green
    } else {
        Write-ColorOutput "❌ Serveur non accessible via ping" $Red
        exit 1
    }
} catch {
    Write-ColorOutput "❌ Erreur lors du test ping : $($_.Exception.Message)" $Red
    exit 1
}

# 2. Test de port SSH
Write-ColorOutput "2️⃣ Test du port SSH ($Port)..." $Yellow
try {
    $tcpClient = New-Object System.Net.Sockets.TcpClient
    $connectTask = $tcpClient.ConnectAsync($ServerHost, $Port)
    $timeoutTask = Start-Sleep -Seconds 10 -PassThru
    
    $completed = $connectTask.Wait(10000) # 10 secondes timeout
    
    if ($completed -and $tcpClient.Connected) {
        Write-ColorOutput "✅ Port SSH accessible" $Green
        $tcpClient.Close()
    } else {
        Write-ColorOutput "❌ Port SSH non accessible" $Red
        exit 1
    }
} catch {
    Write-ColorOutput "❌ Erreur lors du test du port SSH : $($_.Exception.Message)" $Red
    exit 1
}

# 3. Test de connexion SSH (si OpenSSH est installé)
Write-ColorOutput "3️⃣ Test de connexion SSH..." $Yellow
try {
    # Vérifier si OpenSSH est disponible
    $sshPath = Get-Command ssh -ErrorAction SilentlyContinue
    if ($sshPath) {
        Write-ColorOutput "🔑 Test de connexion SSH avec clé..." $Yellow
        $sshCommand = "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=$Timeout -o BatchMode=yes $ServerUser@$ServerHost 'echo \"Connexion SSH réussie !\"'"
        
        Write-ColorOutput "Commande : $sshCommand" $Blue
        
        $result = Invoke-Expression $sshCommand 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-ColorOutput "✅ Connexion SSH réussie !" $Green
            Write-ColorOutput "Réponse du serveur : $result" $Green
        } else {
            Write-ColorOutput "❌ Échec de la connexion SSH" $Red
            Write-ColorOutput "Code d'erreur : $LASTEXITCODE" $Red
            Write-ColorOutput "Message d'erreur : $result" $Red
        }
    } else {
        Write-ColorOutput "⚠️  OpenSSH non installé sur cette machine" $Yellow
        Write-ColorOutput "   Installez OpenSSH ou utilisez PuTTY pour tester" $Yellow
    }
} catch {
    Write-ColorOutput "❌ Erreur lors du test SSH : $($_.Exception.Message)" $Red
}

# 4. Informations de diagnostic
Write-ColorOutput "4️⃣ Informations de diagnostic..." $Yellow
Write-ColorOutput "Serveur : $ServerHost" $Blue
Write-ColorOutput "Utilisateur : $ServerUser" $Blue
Write-ColorOutput "Port : $Port" $Blue
Write-ColorOutput "Timeout : $Timeout secondes" $Blue

# 5. Recommandations
Write-ColorOutput "5️⃣ Recommandations..." $Yellow
Write-ColorOutput ""
Write-ColorOutput "Si la connexion SSH échoue :" $Yellow
Write-ColorOutput "1. Vérifiez que l'utilisateur '$ServerUser' existe sur le serveur" $Blue
Write-ColorOutput "2. Vérifiez que votre clé publique SSH est dans ~/.ssh/authorized_keys" $Blue
Write-ColorOutput "3. Vérifiez les permissions : chmod 700 ~/.ssh && chmod 600 ~/.ssh/authorized_keys" $Blue
Write-ColorOutput "4. Vérifiez la configuration SSH : sudo nano /etc/ssh/sshd_config" $Blue
Write-ColorOutput "5. Redémarrez SSH : sudo systemctl restart ssh" $Blue
Write-ColorOutput ""
Write-ColorOutput "Pour configurer le serveur :" $Yellow
Write-ColorOutput "1. Exécutez le script setup-ssh-server.sh sur le serveur" $Blue
Write-ColorOutput "2. Ajoutez votre clé publique : ssh-copy-id $ServerUser@$ServerHost" $Blue
Write-ColorOutput "3. Testez : ssh $ServerUser@$ServerHost" $Blue

Write-ColorOutput "=========================================" $Blue
Write-ColorOutput "Test terminé !" $Green
