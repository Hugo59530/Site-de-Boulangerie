param(
    [switch]$SkipStart = $false
)

$ErrorActionPreference = "Stop"

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $projectRoot

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "   Deployment La Rhônelle" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan

function Install-NodeJsIfNeeded {
    $nodeCommand = Get-Command node -ErrorAction SilentlyContinue

    if ($nodeCommand) {
        Write-Host "Node.js déjà installé : $((node --version))" -ForegroundColor Green
        return
    }

    Write-Host "Node.js introuvable. Installation en cours..." -ForegroundColor Yellow

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --id OpenJS.NodeJS.LTS --accept-source-agreements --accept-package-agreements --silent
    }
    elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install nodejs-lts -y --no-progress
    }
    else {
        throw "Aucun gestionnaire de paquets détecté pour installer Node.js (winget ou choco)."
    }

    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

    if (-not (Get-Command node -ErrorAction SilentlyContinue)) {
        throw "L'installation de Node.js a échoué ou n'est pas encore disponible dans PATH."
    }

    Write-Host "Node.js installé avec succès : $((node --version))" -ForegroundColor Green
}

function Stop-StaleNodeProcesses {
    $nodeProcesses = Get-Process node -ErrorAction SilentlyContinue

    if ($nodeProcesses) {
        Write-Host "Fermeture des processus Node en cours pour libérer les fichiers verrouillés..." -ForegroundColor Yellow
        $nodeProcesses | Stop-Process -Force
    }
}

function Ensure-Dependencies {
    if (-not (Test-Path "$projectRoot\package.json")) {
        throw "package.json introuvable dans $projectRoot"
    }

    Stop-StaleNodeProcesses

    if (Test-Path "$projectRoot\node_modules") {
        Write-Host "Nettoyage des dépendances existantes pour éviter les conflits Windows..." -ForegroundColor Yellow
        Remove-Item -Recurse -Force "$projectRoot\node_modules"
    }

    Write-Host "Installation des dépendances du projet..." -ForegroundColor Yellow
    & npm install --no-audit --no-fund

    if ($LASTEXITCODE -ne 0) {
        throw "L'installation des dépendances a échoué."
    }
}

function Start-App {
    if ($SkipStart) {
        Write-Host "Le démarrage automatique est désactivé via -SkipStart." -ForegroundColor DarkYellow
        return
    }

    Write-Host "Démarrage de l'application sur http://localhost:3000 ..." -ForegroundColor Green
    Start-Process powershell -ArgumentList "-NoExit", "-Command", "Set-Location '$projectRoot'; npm start" -WindowStyle Normal
}

try {
    Install-NodeJsIfNeeded
    Ensure-Dependencies
    Start-App
    Write-Host "Deploiement terminé avec succès." -ForegroundColor Green
}
catch {
    Write-Error "Erreur pendant le déploiement : $($_.Exception.Message)"
    exit 1
}
