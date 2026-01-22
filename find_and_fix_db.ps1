# Find and fix database
Write-Host "🔍 Looking for database..."

$localAppData = $env:LOCALAPPDATA
$dbPath = "$localAppData\pos_offline_desktop_database\pos_offline_desktop_database.sqlite"

Write-Host "Database path: $dbPath"

if (Test-Path $dbPath) {
    Write-Host "✅ Database found!"
    
    # Create backup
    $backupPath = "$dbPath.backup.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item $dbPath $backupPath
    Write-Host "✅ Database backed up to: $backupPath"
    
    # Check if sqlite3 is available
    try {
        $null = sqlite3 --version 2>$null
        Write-Host "✅ sqlite3 found, applying fixes..."
        
        # Add created_at column
        sqlite3 $dbPath "ALTER TABLE customers ADD COLUMN created_at INTEGER;" 2>$null
        Write-Host "✅ created_at column added"
        
        # Populate created_at
        sqlite3 $dbPath "UPDATE customers SET created_at = CAST(strftime('%s','now') AS INTEGER) WHERE created_at IS NULL;" 2>$null
        Write-Host "✅ created_at column populated"
        
        # Add phone column
        sqlite3 $dbPath "ALTER TABLE customers ADD COLUMN phone TEXT;" 2>$null
        Write-Host "✅ phone column added"
        
        Write-Host "🎉 Database fix completed successfully!"
        Write-Host "Please restart the application and test customer editing."
        
    } catch {
        Write-Host "❌ sqlite3 not found. Please install SQLite3 tools."
        Write-Host "Download from: https://www.sqlite.org/download.html"
    }
} else {
    Write-Host "❌ Database not found at: $dbPath"
    Write-Host "Please run the application first to create the database."
}

Read-Host "Press any key to continue..."
$null = $Host.UI.RawUI.ReadKeyAsSingleLine()
