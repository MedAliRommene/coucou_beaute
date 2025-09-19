# 🔍 Script de Diagnostic du Serveur - Coucou Beauté
# Ce script diagnostique les problèmes de connectivité et de configuration du serveur

param(
    [string]$ServerHost = "196.203.120.35",
    [string]$ServerUser = "vpsuser",
    [int]$Port = 22
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

function Test-BasicConnectivity {
    param([string]$Host)
    
    Write-ColorOutput "`n🌐 Test de connectivité de base vers $Host..." $Cyan
    
    # Test de ping
    Write-ColorOutput "1️⃣ Test de ping..." $Yellow
    try {
        $pingResult = Test-Connection -ComputerName $Host -Count 3 -Quiet
        if ($pingResult) {
            Write-ColorOutput "✅ Ping réussi vers $Host" $Green
        } else {
            Write-ColorOutput "❌ Ping échoué vers $Host" $Red
        }
    } catch {
        Write-ColorOutput "❌ Erreur lors du test ping : $($_.Exception.Message)" $Red
    }
    
    # Test de résolution DNS
    Write-ColorOutput "2️⃣ Test de résolution DNS..." $Yellow
    try {
        $dnsResult = [System.Net.Dns]::GetHostEntry($Host)
        Write-ColorOutput "✅ Résolution DNS réussie : $($dnsResult.HostName)" $Green
        Write-ColorOutput "   Adresses IP : $($dnsResult.AddressList -join ', ')" $Blue
    } catch {
        Write-ColorOutput "❌ Erreur de résolution DNS : $($_.Exception.Message)" $Red
    }
}

function Test-PortConnectivity {
    param([string]$Host, [int]$Port)
    
    Write-ColorOutput "`n🔌 Test de connectivité du port $Port..." $Cyan
    
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
    param([string]$Host, [string]$User)
    
    Write-ColorOutput "`n🔑 Test de connexion SSH..." $Cyan
    
    # Vérifier si OpenSSH est disponible
    $sshPath = Get-Command ssh -ErrorAction SilentlyContinue
    if (-not $sshPath) {
        Write-ColorOutput "❌ OpenSSH non installé sur cette machine" $Red
        return $false
    }
    
    # Test de connexion SSH
    $sshCommand = "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=15 -o BatchMode=yes $User@$Host 'echo \"SSH connection successful\"'"
    
    Write-ColorOutput "Commande : $sshCommand" $Blue
    
    try {
        $result = Invoke-Expression $sshCommand 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-ColorOutput "✅ Connexion SSH réussie" $Green
            Write-ColorOutput "Réponse du serveur : $result" $Green
            return $true
        } else {
            Write-ColorOutput "❌ Échec de la connexion SSH (code: $exitCode)" $Red
            Write-ColorOutput "Message d'erreur : $result" $Red
            return $false
        }
    } catch {
        Write-ColorOutput "❌ Erreur lors du test SSH : $($_.Exception.Message)" $Red
        return $false
    }
}

function Test-WebService {
    param([string]$Host)
    
    Write-ColorOutput "`n🌐 Test du service web..." $Cyan
    
    try {
        $webRequest = Invoke-WebRequest -Uri "http://$Host" -TimeoutSec 10 -UseBasicParsing
        Write-ColorOutput "✅ Service web accessible (code: $($webRequest.StatusCode))" $Green
        Write-ColorOutput "   Serveur : $($webRequest.Headers.Server)" $Blue
    } catch {
        Write-ColorOutput "❌ Service web non accessible : $($_.Exception.Message)" $Red
        
        # Test du port 80
        Write-ColorOutput "🔍 Test du port 80..." $Yellow
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $tcpClient.Connect($Host, 80)
            Write-ColorOutput "✅ Port 80 accessible" $Green
            $tcpClient.Close()
        } catch {
            Write-ColorOutput "❌ Port 80 non accessible" $Red
        }
    }
}

function Show-DiagnosticSummary {
    param([bool]$SSHWorking, [bool]$PortWorking, [bool]$WebWorking)
    
    Write-ColorOutput "`n📊 Résumé du diagnostic :" $Magenta
    Write-ColorOutput "=" * 50 $Magenta
    
    if ($SSHWorking) {
        Write-ColorOutput "✅ SSH : Fonctionnel" $Green
    } else {
        Write-ColorOutput "❌ SSH : Problème détecté" $Red
    }
    
    if ($PortWorking) {
        Write-ColorOutput "✅ Port 22 : Accessible" $Green
    } else {
        Write-ColorOutput "❌ Port 22 : Non accessible" $Red
    }
    
    if ($WebWorking) {
        Write-ColorOutput "✅ Service Web : Fonctionnel" $Green
    } else {
        Write-ColorOutput "❌ Service Web : Problème détecté" $Red
    }
}

function Show-TroubleshootingTips {
    Write-ColorOutput "`n🛠️ Conseils de dépannage :" $Magenta
    Write-ColorOutput "=" * 50 $Magenta
    
    Write-ColorOutput "`nSi SSH ne fonctionne pas :" $Yellow
    Write-ColorOutput "1. Vérifiez que le service SSH est démarré sur le serveur" $Blue
    Write-ColorOutput "2. Vérifiez la configuration du firewall" $Blue
    Write-ColorOutput "3. Vérifiez que l'utilisateur '$ServerUser' existe" $Blue
    Write-ColorOutput "4. Vérifiez les permissions des clés SSH" $Blue
    
    Write-ColorOutput "`nSi le port 22 n'est pas accessible :" $Yellow
    Write-ColorOutput "1. Vérifiez que SSH écoute sur le port 22" $Blue
    Write-ColorOutput "2. Vérifiez la configuration du firewall" $Blue
    Write-ColorOutput "3. Vérifiez que le serveur est en ligne" $Blue
    
    Write-ColorOutput "`nSi le service web ne fonctionne pas :" $Yellow
    Write-ColorOutput "1. Vérifiez que Docker est démarré" $Blue
    Write-ColorOutput "2. Vérifiez les logs des conteneurs" $Blue
    Write-ColorOutput "3. Vérifiez la configuration Nginx" $Blue
}

# Fonction principale
function Start-Diagnostic {
    Write-ColorOutput "🔍 Diagnostic du Serveur - Coucou Beauté" $Magenta
    Write-ColorOutput "=" * 60 $Magenta
    Write-ColorOutput "Ce script diagnostique les problèmes de connectivité et de configuration" $Blue
    Write-ColorOutput ""
    
    # Tests de connectivité
    Test-BasicConnectivity -Host $ServerHost
    
    # Test du port SSH
    $portWorking = Test-PortConnectivity -Host $ServerHost -Port $Port
    
    # Test de connexion SSH
    $sshWorking = Test-SSHConnection -Host $ServerHost -User $ServerUser
    
    # Test du service web
    $webWorking = Test-WebService -Host $ServerHost
    
    # Résumé du diagnostic
    Show-DiagnosticSummary -SSHWorking $sshWorking -PortWorking $portWorking -WebWorking $webWorking
    
    # Conseils de dépannage
    Show-TroubleshootingTips
    
    Write-ColorOutput "`n📋 Prochaines étapes :" $Cyan
    if ($sshWorking) {
        Write-ColorOutput "✅ SSH fonctionne - Le déploiement devrait réussir" $Green
    } else {
        Write-ColorOutput "❌ SSH ne fonctionne pas - Vérifiez la configuration du serveur" $Red
    }
}

# Lancer le diagnostic
Start-Diagnostic
