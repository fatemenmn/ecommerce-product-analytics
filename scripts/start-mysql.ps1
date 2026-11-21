# Start the portable MySQL 8.0 server (no admin rights, no Windows service).
#
#   powershell -ExecutionPolicy Bypass -File scripts\start-mysql.ps1
#
# The server listens on 127.0.0.1:3306 with user root and an empty password.

param(
    [string]$MysqlHome = 'C:\Users\User\mysql',
    [string]$Version   = 'mysql-8.0.44-winx64'
)

$ErrorActionPreference = 'Stop'

$bin    = Join-Path $MysqlHome "$Version\bin"
$mysqld = Join-Path $bin 'mysqld.exe'
$myIni  = Join-Path $MysqlHome 'my.ini'

if (-not (Test-Path $mysqld)) { throw "mysqld.exe not found at $mysqld" }
if (-not (Test-Path $myIni))  { throw "my.ini not found at $myIni" }

$existing = Get-Process mysqld -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "MySQL already running (PID $($existing.Id -join ', '))."
    return
}

Start-Process -FilePath $mysqld `
              -ArgumentList "--defaults-file=$myIni" `
              -WorkingDirectory $bin `
              -WindowStyle Hidden

$client = Join-Path $bin 'mysql.exe'
for ($i = 0; $i -lt 30; $i++) {
    Start-Sleep -Milliseconds 500
    & $client -u root --skip-password -e "SELECT 1" 2>&1 | Out-Null
    if ($LASTEXITCODE -eq 0) {
        Write-Host "MySQL is up on 127.0.0.1:3306."
        return
    }
}
throw "MySQL did not become ready. Check $MysqlHome\mysql-error.log"
