# ---------------------------------------------------------------------------
# Inazuma validator installer - Windows 10/11 (PowerShell)
#
#   irm https://raw.githubusercontent.com/inazuma-network/inazuma-validator/main/scripts/install-validator.ps1 | iex
#
# Everything lives under %USERPROFILE%\.inazuma - no admin rights required.
#   binary   ~\.inazuma\bin\inazuma.exe
#   data     ~\.inazuma\data
#   config   ~\.inazuma\genesis.json, ~\.inazuma\validator.env
#   service  Scheduled Task "InazumaNode" (starts at logon, restarts on fail)
#
# NOTE: Windows desktops sleep and update-reboot. Use this for development.
# Run production validators on a Linux server with a static IP.
# ---------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'

$Seed    = if ($env:INAZ_PEERS) { $env:INAZ_PEERS } else { 'rpc.inazuma.network:9944' }
$Role    = if ($env:INAZ_ROLE)  { $env:INAZ_ROLE }  else { 'validator' }
$RepoUrl = if ($env:INAZ_REPO)  { $env:INAZ_REPO }  else { 'https://github.com/inazuma-network/inazuma-core.git' }
$GenesisUrl = 'https://raw.githubusercontent.com/inazuma-network/inazuma-core/main/genesis.json'
$Home_   = Join-Path $env:USERPROFILE '.inazuma'
$Src     = Join-Path $env:USERPROFILE 'inazuma-core'
$Bin     = Join-Path $Home_ 'bin\inazuma.exe'
$EnvFile = Join-Path $Home_ 'validator.env'

function C($m)    { Write-Host $m -ForegroundColor Magenta }
function Ok($m)   { Write-Host "  [ok] $m" -ForegroundColor Magenta }
function Step($m) { Write-Host ""; C "-- $m ------------------------------" }
function Die($m)  { Write-Host "  [x] $m" -ForegroundColor Red; exit 1 }

New-Item -ItemType Directory -Force -Path "$Home_\bin","$Home_\logs" | Out-Null
C ""; C "  INAZUMA VALIDATOR INSTALLER - Windows"; C "  role=$Role  seed=$Seed"; C ""

Step "1/6  Checking this PC"
$cpu = (Get-CimInstance Win32_ComputerSystem).NumberOfLogicalProcessors
$ram = [math]::Round((Get-CimInstance Win32_ComputerSystem).TotalPhysicalMemory / 1GB)
$disk = [math]::Round((Get-PSDrive C).Free / 1GB)
Write-Host "  cpu $cpu cores - ram $ram GB - free disk $disk GB"
if ($cpu -lt 2)  { Write-Host "  ! 2 cores is the minimum." }
if ($ram -lt 4)  { Write-Host "  ! 8 GB RAM recommended." }
if ($disk -lt 40) { Die "Need at least 50 GB free on C:." }
Ok "machine looks usable"

Step "2/6  Toolchain (git + Rust MSVC)"
function Have($c) { $null -ne (Get-Command $c -ErrorAction SilentlyContinue) }
if (-not (Have git)) {
  if (Have winget) { winget install --id Git.Git -e --source winget --accept-package-agreements --accept-source-agreements | Out-Null }
  else { Die "Install Git from https://git-scm.com/download/win then re-run." }
}
if (-not (Have cargo)) {
  if (Have winget) { winget install --id Rustlang.Rustup -e --accept-package-agreements --accept-source-agreements | Out-Null }
  else {
    $ru = Join-Path $env:TEMP 'rustup-init.exe'
    Invoke-WebRequest 'https://win.rustup.rs/x86_64' -OutFile $ru
    & $ru -y --profile minimal | Out-Null
  }
  $env:Path = "$env:USERPROFILE\.cargo\bin;$env:Path"
}
$env:Path = "$env:USERPROFILE\.cargo\bin;$env:Path"
if (-not (Have cargo)) { Die "Rust did not install. Open a new PowerShell window and re-run." }
if (-not (Have link)) { Write-Host "  ! If the build fails with 'link.exe not found', install Visual Studio Build Tools (C++ workload): https://aka.ms/vs/17/release/vs_BuildTools.exe" }
Ok "rust $((rustc --version) -split ' ' | Select-Object -Index 1)"

Step "3/6  Building the node (10-20 minutes the first time)"
if (Test-Path "$Src\.git") { git -C $Src pull --ff-only -q } else { git clone -q $RepoUrl $Src }
Push-Location $Src; cargo build --release; Pop-Location
Copy-Item "$Src\target\release\inazuma.exe" $Bin -Force
Ok "installed to $Bin"

Step "4/6  Key and genesis"
if (Test-Path $EnvFile) { Ok "existing key kept ($EnvFile)" }
elseif ($Role -eq 'replica') { '' | Set-Content $EnvFile; Ok "replica - no key, no slashing risk" }
else {
  $out = & $Bin keygen | Out-String
  $secret = ([regex]'[0-9a-fA-F]{64,}').Match($out).Value
  $addr   = ([regex]'[1-9A-HJ-NP-Za-km-z]{32,48}').Match($out).Value
  "INAZ_KEY=$secret`nINAZ_ADDRESS=$addr" | Set-Content $EnvFile
  icacls $EnvFile /inheritance:r /grant:r "$($env:USERNAME):(R,W)" | Out-Null
  Ok "key created - back up $EnvFile offline NOW"
}
if (-not (Test-Path "$Home_\genesis.json")) {
  if (Test-Path "$Src\genesis.json") { Copy-Item "$Src\genesis.json" "$Home_\genesis.json" }
  else { Invoke-WebRequest $GenesisUrl -OutFile "$Home_\genesis.json" }
}
if (-not (Test-Path "$Home_\data")) { & $Bin init --data "$Home_\data" --genesis "$Home_\genesis.json" }
Ok "data dir ready"

Step "5/6  Scheduled Task (starts at logon, restarts on failure)"
$key = ''
if (Test-Path $EnvFile) {
  foreach ($line in Get-Content $EnvFile) { if ($line -match '^INAZ_KEY=(.+)$') { $key = $Matches[1] } }
}
$args = "run --data `"$Home_\data`" --genesis `"$Home_\genesis.json`" --peers $Seed --rpc 127.0.0.1:9933"
if ($key) { $args = "run --data `"$Home_\data`" --genesis `"$Home_\genesis.json`" --key $key --peers $Seed --rpc 127.0.0.1:9933" }
$action   = New-ScheduledTaskAction -Execute $Bin -Argument $args
$trigger  = New-ScheduledTaskTrigger -AtLogOn
$settings = New-ScheduledTaskSettingsSet -RestartCount 999 -RestartInterval (New-TimeSpan -Minutes 1) -ExecutionTimeLimit ([TimeSpan]::Zero) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
Unregister-ScheduledTask -TaskName 'InazumaNode' -Confirm:$false -ErrorAction SilentlyContinue
Register-ScheduledTask -TaskName 'InazumaNode' -Action $action -Trigger $trigger -Settings $settings | Out-Null
Start-ScheduledTask -TaskName 'InazumaNode'
Ok "task InazumaNode registered and started"

Step "6/6  Done"
$addr = ''
if (Test-Path $EnvFile) { foreach ($l in Get-Content $EnvFile) { if ($l -match '^INAZ_ADDRESS=(.+)$') { $addr = $Matches[1] } } }
C ""
if ($addr) { C "  your address:  $addr" }
Write-Host @"

  status   & "$Bin" status
  stop     Stop-ScheduledTask -TaskName InazumaNode
  start    Start-ScheduledTask -TaskName InazumaNode

  Open TCP 9944 inbound if you want inbound peers:
    New-NetFirewallRule -DisplayName "Inazuma P2P" -Direction Inbound -Protocol TCP -LocalPort 9944 -Action Allow

  Next: fund your address, wait until status says in sync, then bond:
    & "$Bin" stake --key <SECRET> --amount 1000

  Track your node at https://inazuma.network/validators
"@
