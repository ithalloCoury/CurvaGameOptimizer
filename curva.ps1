<#
.SYNOPSIS
    Curva Game Optimizer — Bootstrapper Portátil para PowerShell (estilo irm ... | iex)
.DESCRIPTION
    Permite executar o Curva Game Optimizer diretamente via PowerShell sem instalação:
    - Remoto (GitHub / Servidor HTTP):
        irm https://SEU_DOMINIO_OU_GITHUB_RAW/curva.ps1 | iex
    - Local / Rede Local (LAN):
        irm http://localhost:8765/curva.ps1 | iex
        ou:
        iex (Get-Content "C:\Users\ithal\.gemini\antigravity\scratch\CurvaGameOptimizer\curva.ps1" -Raw)

    Créditos: Ithallo Coury
#>

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12 -bor [Net.SecurityProtocolType]::Tls13

Write-Host ""
Write-Host "  ================================================================" -ForegroundColor Cyan
Write-Host "   ⚡ CURVA GAME OPTIMIZER — MODO PORTÁTIL (WINDOWS 11 x64)" -ForegroundColor Cyan
Write-Host "   Créditos: Ithallo Coury" -ForegroundColor DarkCyan
Write-Host "  ================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. Configura URL de download remoto (caso publicado no GitHub Releases ou servidor próprio)
#    Pode ser sobrescrita definindo $env:CURVA_PORTABLE_URL antes de rodar o irm | iex
$DefaultRemoteExeUrl = if ($env:CURVA_PORTABLE_URL) {
    $env:CURVA_PORTABLE_URL
} else {
    "https://github.com/ithalloCoury/CurvaGameOptimizer/releases/latest/download/CurvaGameOptimizer-Portable.exe"
}

# 2. Diretório temporário portátil na máquina alvo
$PortableWorkDir = Join-Path $env:TEMP "CurvaGameOptimizer-Portable"
$PortableDataDir = Join-Path $PortableWorkDir "CurvaData"
$TargetExePath   = Join-Path $PortableWorkDir "CurvaGameOptimizer-Portable.exe"

New-Item -ItemType Directory -Force -Path $PortableWorkDir | Out-Null
New-Item -ItemType Directory -Force -Path $PortableDataDir | Out-Null
Set-Content -Path (Join-Path $PortableWorkDir "portable.flag") -Value "portable=true" -Encoding UTF8

# 3. Procura primeiro o binário portátil single-file local (se executado na máquina de build/LAN)
$CandidateLocalPaths = @(
    "C:\Users\ithal\.gemini\antigravity\scratch\CurvaGameOptimizer\publish\portable\CurvaGameOptimizer-Portable.exe",
    "C:\Users\ithal\.gemini\antigravity\scratch\CurvaGameOptimizer\publish\portable\CurvaGameOptimizer.exe",
    (Join-Path $PSScriptRoot "publish\portable\CurvaGameOptimizer-Portable.exe"),
    (Join-Path $PSScriptRoot "CurvaGameOptimizer-Portable.exe"),
    $TargetExePath
) | Where-Object { $_ -and (Test-Path $_) }

$ExeToLaunch = $null

if ($CandidateLocalPaths.Count -gt 0) {
    $SourceExe = $CandidateLocalPaths[0]
    Write-Host "[✓] Executável portátil localizado: $SourceExe" -ForegroundColor Green
    if ($SourceExe -ne $TargetExePath) {
        try {
            Copy-Item -Path $SourceExe -Destination $TargetExePath -Force -ErrorAction Stop
            $ExeToLaunch = $TargetExePath
        } catch {
            # Se o destino já estiver aberto, executa direto da origem
            $ExeToLaunch = $SourceExe
        }
    } else {
        $ExeToLaunch = $TargetExePath
    }
} else {
    Write-Host "[↓] Baixando CurvaGameOptimizer-Portable.exe de:" -ForegroundColor Yellow
    Write-Host "    $DefaultRemoteExeUrl" -ForegroundColor Gray
    try {
        Invoke-WebRequest -Uri $DefaultRemoteExeUrl -OutFile $TargetExePath -UseBasicParsing
        $ExeToLaunch = $TargetExePath
        Write-Host "[✓] Download concluído em: $TargetExePath" -ForegroundColor Green
    } catch {
        Write-Host "[!] Não foi possível baixar de $DefaultRemoteExeUrl." -ForegroundColor Red
        Write-Host "    Configure a variável `$env:CURVA_PORTABLE_URL com o link direto do seu CurvaGameOptimizer-Portable.exe." -ForegroundColor Yellow
        return
    }
}

# 4. Inicia o aplicativo portátil com elevação UAC (necessário para sensores PawnIO/SuperIO, energia e WPR ETW)
Write-Host "[⚡] Iniciando Curva Game Optimizer (Portátil)..." -ForegroundColor Cyan
$env:CURVA_DATA_DIR = $PortableDataDir

$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

if ($IsAdmin) {
    Start-Process -FilePath $ExeToLaunch -ArgumentList "--portable" -WorkingDirectory (Split-Path $ExeToLaunch -Parent)
} else {
    Write-Host "[i] Solicitando permissão de Administrador (UAC) para leitura completa de sensores e controle de fans..." -ForegroundColor Yellow
    Start-Process -FilePath $ExeToLaunch -ArgumentList "--portable" -WorkingDirectory (Split-Path $ExeToLaunch -Parent) -Verb RunAs
}

Write-Host "[✓] Curva Game Optimizer iniciado com sucesso!" -ForegroundColor Green
