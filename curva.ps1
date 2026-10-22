<#
.SYNOPSIS
    Curva Game Optimizer - Bootstrapper Portatil para PowerShell (irm ... | iex)
.DESCRIPTION
    Executa o Curva Game Optimizer diretamente via PowerShell sem instalacao:
        irm https://raw.githubusercontent.com/ithalloCoury/CurvaGameOptimizer/main/curva.ps1 | iex
    Creditos: Ithallo Coury
#>

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

Write-Host ""
Write-Host "  ================================================================" -ForegroundColor Cyan
Write-Host "   CURVA GAME OPTIMIZER - MODO PORTATIL (WINDOWS 11 x64)" -ForegroundColor Cyan
Write-Host "   Creditos: Ithallo Coury" -ForegroundColor DarkCyan
Write-Host "  ================================================================" -ForegroundColor Cyan
Write-Host ""

# 1. URL oficial do executavel portatil no GitHub Releases
$DefaultRemoteExeUrl = if ($env:CURVA_PORTABLE_URL) {
    $env:CURVA_PORTABLE_URL
} else {
    "https://github.com/ithalloCoury/CurvaGameOptimizer/releases/latest/download/CurvaGameOptimizer-Portable.exe"
}

# 2. Diretorio temporario portatil na maquina alvo
$PortableWorkDir = Join-Path $env:TEMP "CurvaGameOptimizer-Portable"
$PortableDataDir = Join-Path $PortableWorkDir "CurvaData"
$TargetExePath   = Join-Path $PortableWorkDir "CurvaGameOptimizer-Portable.exe"

New-Item -ItemType Directory -Force -Path $PortableWorkDir | Out-Null
New-Item -ItemType Directory -Force -Path $PortableDataDir | Out-Null
Set-Content -Path (Join-Path $PortableWorkDir "portable.flag") -Value "portable=true" -Encoding UTF8

# 3. Monta a lista de caminhos locais de forma segura (quando rodado via irm | iex, $PSScriptRoot e vazio)
$CandidateList = New-Object System.Collections.Generic.List[string]
$CandidateList.Add("C:\Users\ithal\.gemini\antigravity\scratch\CurvaGameOptimizer\publish\portable\CurvaGameOptimizer-Portable.exe")
$CandidateList.Add("C:\Users\ithal\.gemini\antigravity\scratch\CurvaGameOptimizer\publish\portable\CurvaGameOptimizer.exe")
if (-not [string]::IsNullOrWhiteSpace($PSScriptRoot)) {
    $CandidateList.Add((Join-Path $PSScriptRoot "publish\portable\CurvaGameOptimizer-Portable.exe"))
    $CandidateList.Add((Join-Path $PSScriptRoot "CurvaGameOptimizer-Portable.exe"))
}
$CandidateList.Add($TargetExePath)

$ExistingLocal = $CandidateList | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path -LiteralPath $_) } | Select-Object -First 1
$ExeToLaunch = $null

if ($ExistingLocal) {
    Write-Host "[OK] Executavel portatil localizado: $ExistingLocal" -ForegroundColor Green
    if ($ExistingLocal -ne $TargetExePath) {
        try {
            Copy-Item -LiteralPath $ExistingLocal -Destination $TargetExePath -Force -ErrorAction Stop
            $ExeToLaunch = $TargetExePath
        } catch {
            $ExeToLaunch = $ExistingLocal
        }
    } else {
        $ExeToLaunch = $TargetExePath
    }
} else {
    Write-Host "[Download] Baixando CurvaGameOptimizer-Portable.exe do GitHub Releases..." -ForegroundColor Yellow
    Write-Host "           $DefaultRemoteExeUrl" -ForegroundColor Gray
    try {
        Invoke-WebRequest -Uri $DefaultRemoteExeUrl -OutFile $TargetExePath -UseBasicParsing
        $ExeToLaunch = $TargetExePath
        Write-Host "[OK] Download concluido em: $TargetExePath" -ForegroundColor Green
    } catch {
        Write-Host "[ERRO] Falha ao baixar de: $DefaultRemoteExeUrl" -ForegroundColor Red
        Write-Host "       Verifique se o Release no GitHub possui o arquivo CurvaGameOptimizer-Portable.exe anexado." -ForegroundColor Yellow
        return
    }
}

# 4. Inicia o aplicativo portatil com elevacao UAC
Write-Host "[Iniciando] Abrindo Curva Game Optimizer (Portatil)..." -ForegroundColor Cyan
$env:CURVA_DATA_DIR = $PortableDataDir
$WorkDir = Split-Path -Path $ExeToLaunch -Parent

$IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)

if ($env:CURVA_DRY_RUN -eq "1") {
    Write-Host "[OK] Validacao concluida: $ExeToLaunch" -ForegroundColor Green
    return
}

if ($IsAdmin) {
    Start-Process -FilePath $ExeToLaunch -ArgumentList "--portable" -WorkingDirectory $WorkDir
} else {
    Write-Host "[UAC] Solicitando permissao de Administrador..." -ForegroundColor Yellow
    Start-Process -FilePath $ExeToLaunch -ArgumentList "--portable" -WorkingDirectory $WorkDir -Verb RunAs
}

Write-Host "[OK] Curva Game Optimizer iniciado com sucesso!" -ForegroundColor Green
