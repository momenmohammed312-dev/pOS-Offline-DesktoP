@echo off
echo 🎯 TARGETED DATABASE FIX
echo.

REM Use the exact path from the app code
set DB_DIR=%LOCALAPPDATA%\pos_offline_desktop_database
set DB_PATH=%DB_DIR%\pos_offline_desktop_database.sqlite

echo Database path: %DB_PATH%

if exist "%DB_PATH%" (
    echo ✅ Database found!
    
    REM Create backup
    copy "%DB_PATH%" "%DB_PATH%.backup.%DATE:~0,4%%TIME:~0,2%"
    echo ✅ Database backed up
    
    REM Apply fixes
    echo Adding created_at column...
    sqlite3 "%DB_PATH%" "ALTER TABLE customers ADD COLUMN created_at INTEGER;" 2>nul
    
    echo Populating created_at...
    sqlite3 "%DB_PATH%" "UPDATE customers SET created_at = CAST(strftime('%%s','now') AS INTEGER) WHERE created_at IS NULL;" 2>nul
    
    echo Adding phone column...
    sqlite3 "%DB_PATH%" "ALTER TABLE customers ADD COLUMN phone TEXT;" 2>nul
    
    echo ✅ Database fix completed!
    echo Please restart the application and test customer editing.
    
) else (
    echo ❌ Database not found at: %DB_PATH%
    echo Please ensure the application is running to create the database first.
)

echo.
pause
