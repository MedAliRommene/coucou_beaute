# 🔧 Test de Syntaxe du Workflow - Coucou Beauté
# Ce script teste la syntaxe du workflow GitHub Actions

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

function Test-WorkflowSyntax {
    Write-ColorOutput "🔧 Test de Syntaxe du Workflow GitHub Actions" $Magenta
    Write-ColorOutput "=" * 60 $Magenta
    Write-ColorOutput ""
    
    # Vérifier que le fichier workflow existe
    $workflowFile = ".github/workflows/deploy.yml"
    if (Test-Path $workflowFile) {
        Write-ColorOutput "✅ Fichier workflow trouvé : $workflowFile" $Green
    } else {
        Write-ColorOutput "❌ Fichier workflow non trouvé : $workflowFile" $Red
        return
    }
    
    # Lire le contenu du workflow
    $content = Get-Content $workflowFile -Raw
    
    # Vérifier les erreurs de syntaxe communes
    Write-ColorOutput "`n🔍 Vérification des erreurs de syntaxe..." $Cyan
    
    # Vérifier l'utilisation de 'local' en dehors des fonctions
    $localOutsideFunction = $content -match "^\s*local\s+"
    if ($localOutsideFunction) {
        Write-ColorOutput "❌ Erreur trouvée : 'local' utilisé en dehors d'une fonction" $Red
        Write-ColorOutput "   Ligne problématique :" $Yellow
        $content -split "`n" | ForEach-Object -Begin {$i=1} -Process {
            if ($_ -match "^\s*local\s+") {
                Write-ColorOutput "   Ligne $i : $_" $Red
            }
            $i++
        }
    } else {
        Write-ColorOutput "✅ Aucune utilisation incorrecte de 'local' trouvée" $Green
    }
    
    # Vérifier la structure YAML
    Write-ColorOutput "`n🔍 Vérification de la structure YAML..." $Cyan
    
    # Vérifier les indentations
    $lines = $content -split "`n"
    $indentationIssues = @()
    for ($i = 0; $i -lt $lines.Length; $i++) {
        $line = $lines[$i]
        if ($line -match "^\s*-\s+name:") {
            # Ligne de step, vérifier l'indentation
            if ($line -notmatch "^\s{4}-\s+name:") {
                $indentationIssues += "Ligne $($i+1): Indentation incorrecte pour step"
            }
        }
    }
    
    if ($indentationIssues.Count -gt 0) {
        Write-ColorOutput "❌ Problèmes d'indentation trouvés :" $Red
        $indentationIssues | ForEach-Object { Write-ColorOutput "   $_" $Red }
    } else {
        Write-ColorOutput "✅ Indentation YAML correcte" $Green
    }
    
    # Vérifier les variables GitHub Actions
    Write-ColorOutput "`n🔍 Vérification des variables GitHub Actions..." $Cyan
    
    $secrets = @("SSH_PRIVATE_KEY", "SERVER_USER", "SERVER_HOST", "DOCKER_USERNAME", "DOCKER_PASSWORD")
    $missingSecrets = @()
    
    foreach ($secret in $secrets) {
        if ($content -notmatch "secrets\.$secret") {
            $missingSecrets += $secret
        }
    }
    
    if ($missingSecrets.Count -gt 0) {
        Write-ColorOutput "⚠️  Secrets manquants dans le workflow :" $Yellow
        $missingSecrets | ForEach-Object { Write-ColorOutput "   - $_" $Yellow }
    } else {
        Write-ColorOutput "✅ Tous les secrets requis sont présents" $Green
    }
    
    # Résumé
    Write-ColorOutput "`n📊 Résumé du test :" $Magenta
    Write-ColorOutput "=" * 50 $Magenta
    
    if ($localOutsideFunction -or $indentationIssues.Count -gt 0) {
        Write-ColorOutput "❌ Des erreurs de syntaxe ont été trouvées" $Red
        Write-ColorOutput "   Corrigez ces erreurs avant de pousser le workflow" $Yellow
    } else {
        Write-ColorOutput "✅ Aucune erreur de syntaxe majeure trouvée" $Green
        Write-ColorOutput "   Le workflow devrait fonctionner correctement" $Green
    }
    
    Write-ColorOutput "`n🚀 Prochaines étapes :" $Cyan
    Write-ColorOutput "1. Commitez et poussez les corrections" $Blue
    Write-ColorOutput "2. Surveillez le déploiement dans GitHub Actions" $Blue
    Write-ColorOutput "3. Vérifiez que le workflow passe maintenant" $Blue
}

# Lancer le test
Test-WorkflowSyntax
