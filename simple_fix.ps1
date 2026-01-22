# Simple database fix
$localAppData = $env:LOCALAPPDATA
$dbPath = "$localAppData\pos_offline_desktop_database\pos_offline_desktop_database.sqlite"

Write-Host "Database path: $dbPath"

if (Test-Path $dbPath) {
    Write-Host "Database found - creating backup..."
    $backupPath = "$dbPath.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $dbPath $backupPath
    Write-Host "Backup created: $backupPath"
    
    try {
        $null = sqlite3 --version 2>$null
        Write-Host "Running SQL fixes..."
        
        sqlite3 $dbPath "ALTER TABLE customers ADD COLUMN created_at INTEGER;" 2>$null
        sqlite3 $dbPath "UPDATE customers SET created_at = CAST(strftime('%s','now') AS INTEGER) WHERE created_at IS NULL;" 2>$null
        sqlite3 $dbPath "ALTER TABLE customers ADD COLUMN phone TEXT;" 2>$null
        
        Write-Host "Database fix completed successfully!"
        Write-Host "Please restart the application and test customer editing."
        
    } catch {
        Write-Host "Error: sqlite3 not found or failed"
    }
} else {
    Write-Host "Database not found. Please run the application first."
}

Read-Host "Press any key to continue..."
$Host.UI.RawUI.ReadKeyAsSingleLine() | Out-Null
