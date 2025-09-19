# 🔧 Script de Test pour la Correction du Workflow - Coucou Beauté
# Ce script teste les corrections apportées au workflow GitHub Actions

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

function Test-PortConnectivity {
    param([string]$Host, [int]$Port)
    
    Write-ColorOutput "`n🔍 Test de connectivité du port $Port vers $Host..." $Cyan
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $connectTask = $tcpClient.ConnectAsync($Host, $Port)
        $timeoutTask = Start-Sleep -Seconds 15 -PassThru
        
        $completed = $connectTask.Wait(15000) # 15 secondes timeout
        
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
    
    Write-ColorOutput "`n🔍 Test de connexion SSH vers $User@$Host..." $Cyan
    
    # Vérifier si OpenSSH est disponible
    $sshPath = Get-Command ssh -ErrorAction SilentlyContinue
    if (-not $sshPath) {
        Write-ColorOutput "❌ OpenSSH non installé sur cette machine" $Red
        return $false
    }
    
    # Test avec les nouveaux paramètres optimisés
    $sshCommand = "ssh -o StrictHostKeyChecking=no -o ConnectTimeout=20 -o ServerAliveInterval=5 -o ServerAliveCountMax=3 -o TCPKeepAlive=yes -o BatchMode=yes -o UserKnownHostsFile=/dev/null $User@$Host 'echo \"SSH connection successful\"'"
    
    Write-ColorOutput "Commande : $sshCommand" $Blue
    
    try {
        $result = Invoke-Expression $sshCommand 2>&1
        $exitCode = $LASTEXITCODE
        
        if ($exitCode -eq 0) {
            Write-ColorOutput "✅ Connexion SSH réussie avec les nouveaux paramètres" $Green
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

function Show-WorkflowImprovements {
    Write-ColorOutput "`n📋 Améliorations apportées au workflow :" $Magenta
    Write-ColorOutput "=" * 60 $Magenta
    
    Write-ColorOutput "`n1️⃣ Test de Connectivité Réseau :" $Cyan
    Write-ColorOutput "   ✅ Test du port SSH prioritaire (plus fiable que ping)" $Green
    Write-ColorOutput "   ✅ Ping ICMP optionnel (ne bloque pas si échoue)" $Green
    Write-ColorOutput "   ✅ Timeout de 15s pour le test de port" $Green
    
    Write-ColorOutput "`n2️⃣ Test de Connexion SSH :" $Cyan
    Write-ColorOutput "   ✅ 5 tentatives au lieu de 3" $Green
    Write-ColorOutput "   ✅ Délai progressif : 5s, 10s, 15s, 20s, 25s" $Green
    Write-ColorOutput "   ✅ Timeout de connexion : 20s par tentative" $Green
    Write-ColorOutput "   ✅ Paramètres SSH optimisés" $Green
    
    Write-ColorOutput "`n3️⃣ Vérification des Secrets :" $Cyan
    Write-ColorOutput "   ✅ Vérification de la présence des secrets requis" $Green
    Write-ColorOutput "   ✅ Affichage des valeurs (masquées pour la sécurité)" $Green
    
    Write-ColorOutput "`n4️⃣ Paramètres SSH Optimisés :" $Cyan
    Write-ColorOutput "   ✅ ConnectTimeout=20 (au lieu de 30)" $Green
    Write-ColorOutput "   ✅ ServerAliveInterval=5 (au lieu de 10)" $Green
    Write-ColorOutput "   ✅ UserKnownHostsFile=/dev/null (évite les problèmes de known_hosts)" $Green
    Write-ColorOutput "   ✅ TCPKeepAlive=yes (maintient la connexion)" $Green
}

function Show-ExpectedResults {
    Write-ColorOutput "`n🎯 Résultats attendus :" $Magenta
    Write-ColorOutput "=" * 50 $Magenta
    
    Write-ColorOutput "`n✅ Le workflow devrait maintenant :" $Green
    Write-ColorOutput "   1. Vérifier les secrets GitHub" $Blue
    Write-ColorOutput "   2. Tester le port SSH (22) - SUCCÈS" $Blue
    Write-ColorOutput "   3. Tester le ping ICMP - ÉCHEC (normal, bloqué par le serveur)" $Blue
    Write-ColorOutput "   4. Tester la connexion SSH - SUCCÈS" $Blue
    Write-ColorOutput "   5. Déployer l'application - SUCCÈS" $Blue
    
    Write-ColorOutput "`n⚠️  Note importante :" $Yellow
    Write-ColorOutput "   Le ping ICMP peut échouer (100% packet loss) car de nombreux" $Blue
    Write-ColorOutput "   serveurs de production bloquent les pings pour la sécurité." $Blue
    Write-ColorOutput "   C'est normal et n'affecte pas le déploiement SSH." $Blue
}

# Fonction principale
function Start-WorkflowTest {
    Write-ColorOutput "🔧 Test de Correction du Workflow - Coucou Beauté" $Magenta
    Write-ColorOutput "=" * 60 $Magenta
    Write-ColorOutput "Ce script teste les corrections apportées au workflow GitHub Actions" $Blue
    Write-ColorOutput ""
    
    # Test de connectivité du port
    if (-not (Test-PortConnectivity -Host $ServerHost -Port $Port)) {
        Write-ColorOutput "❌ Test de connectivité du port échoué" $Red
        Write-ColorOutput "Le workflow échouera probablement aussi." $Red
        return
    }
    
    # Test de connexion SSH
    if (Test-SSHConnection -Host $ServerHost -User $ServerUser) {
        Write-ColorOutput "`n🎉 Tests réussis !" $Green
        Write-ColorOutput "Votre workflow GitHub Actions devrait maintenant fonctionner." $Green
    } else {
        Write-ColorOutput "`n❌ Test SSH échoué" $Red
        Write-ColorOutput "Vérifiez votre configuration SSH." $Red
    }
    
    Show-WorkflowImprovements
    Show-ExpectedResults
    
    Write-ColorOutput "`n📋 Prochaines étapes :" $Cyan
    Write-ColorOutput "1. Commitez et poussez les changements" $Green
    Write-ColorOutput "2. Surveillez le déploiement dans GitHub Actions" $Green
    Write-ColorOutput "3. Vérifiez que le workflow passe maintenant" $Green
}

# Lancer le test
Start-WorkflowTest
