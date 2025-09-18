# Script PowerShell pour ajouter la clé SSH publique au serveur
# Usage: .\add_ssh_key_automated.ps1

$SERVER_HOST = "196.203.120.35"
$SERVER_USER = "vpsuser"
$SERVER_PASSWORD = "VPS-adminUser@2025"

# Clé publique SSH
$PUBLIC_KEY = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDPAqjcsRWNwxaY7BzjOvDUc1a3/j4m0EysU+CeECiGmKc+9NUYPK3B5ttNwlDsNIlORCXg1tau3AY5xg+foMKSESH0RT3MSg3pZ1aOZoxdAq6WDMgxGcXL2DbzBtf5K5UMXDHYM1SKnK7+ZHayzoSJrXAa2+K42WoFz+sUFFdbDNJIajJdD9lOaK7VyjlbkUb5X0JiVIUjt0bow8A2ZW7TXEH7lzCOu6TYsLU7v07cd4ednlT8eK1orx42wkwtvkB7UdNc3XgGO9YPCXqA34+HlNz+730oCMqYEKUoZgS3FmC8Da9XWuzEWKMj+Zo2KnN0u6MvYyTtLbkHxCANHnoWZQEa0m7U0dpcXPTb0SxlPcTlVjx0BcAhi9INIWC4zCboSZCkKgXIgwsnUaOLyj1JvUIXow+YwWuq4k2LOGcMUqDsrZMFH9rFVX3VKbAgZZJ7/ksclIGQYeXQp+vQCXVj7p1FggBaK+kC/Kc4LdaKjX5g/KVilU3hY7l9UHIerPUIKPCC8fBQfq80rXZKtI/nmod9hmmtHIXBh9euHSIj0qY9Z6pFQ9dAZEBuwOUwnrh3B97zGgdAncxhL9UOWjjMLzrnI4I1AcOhNtg3kQW16o2Rz2EL3MInHEUWystgL7oCYr66sxsnrERs4BuhwxMID0NS+trL9Pqy4cAOwbfyfQ== github-actions-coucou-beaute"

Write-Host "🔑 Ajout de la clé SSH publique au serveur..." -ForegroundColor Green

# Créer un fichier temporaire avec les commandes à exécuter
$commands = @"
mkdir -p ~/.ssh
echo '$PUBLIC_KEY' >> ~/.ssh/authorized_keys
chmod 700 ~/.ssh
chmod 600 ~/.ssh/authorized_keys
echo '✅ Clé SSH publique ajoutée avec succès !'
cat ~/.ssh/authorized_keys
"@

# Écrire les commandes dans un fichier temporaire
$tempFile = [System.IO.Path]::GetTempFileName()
$commands | Out-File -FilePath $tempFile -Encoding UTF8

try {
    # Exécuter les commandes via SSH
    $process = Start-Process -FilePath "ssh" -ArgumentList "-o", "StrictHostKeyChecking=no", "${SERVER_USER}@${SERVER_HOST}", "bash -s" -RedirectStandardInput $tempFile -Wait -PassThru -NoNewWindow
    
    if ($process.ExitCode -eq 0) {
        Write-Host "🎉 Configuration SSH terminée avec succès !" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors de la configuration SSH" -ForegroundColor Red
    }
} catch {
    Write-Host "❌ Erreur: $_" -ForegroundColor Red
} finally {
    # Nettoyer le fichier temporaire
    Remove-Item $tempFile -Force
}

Write-Host "`n🔧 Test de la connexion SSH..." -ForegroundColor Yellow
ssh -i C:\Users\Lenovo\.ssh\coucou_beaute_rsa vpsuser@196.203.120.35 "echo 'Test de connexion SSH réussi !'"
