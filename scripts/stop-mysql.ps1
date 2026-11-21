# Stop the portable MySQL 8.0 server gracefully.
#
#   powershell -ExecutionPolicy Bypass -File scripts\stop-mysql.ps1

param(
    [string]$MysqlHome = 'C:\Users\User\mysql',
    [string]$Version   = 'mysql-8.0.44-winx64'
)

$admin = Join-Path $MysqlHome "$Version\bin\mysqladmin.exe"

if (-not (Get-Process mysqld -ErrorAction SilentlyContinue)) {
    Write-Host 'MySQL is not running.'
    return
}

& $admin -u root --skip-password shutdown 2>$null
Start-Sleep -Seconds 2

$left = Get-Process mysqld -ErrorAction SilentlyContinue
if ($left) {
    Write-Host 'Graceful shutdown timed out; forcing stop.'
    $left | Stop-Process -Force
} else {
    Write-Host 'MySQL stopped.'
}
