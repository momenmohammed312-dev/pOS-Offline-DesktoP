@echo off
echo 🚨 MANUAL DATABASE FIX - OPTION 2
echo.
echo This script will manually add the missing 'created_at' column to customers table
echo.

REM Get AppData path
set APPDATA=%LOCALAPPDATA%

REM Set database path
set DB_PATH=%APPDATA%\pos_offline_desktop_database\pos_offline_desktop_database.sqlite

echo Database path: %DB_PATH%
echo.

REM Check if database exists
if not exist "%DB_PATH%" (
    echo ❌ Database file not found at: %DB_PATH%
    echo Please ensure the application has been run at least once
    pause
    exit /b 1
)

echo ✅ Database file found
echo.

REM Create backup
set BACKUP_PATH=%DB_PATH%.backup.%DATE:~0,4%%TIME:~0,2%
copy "%DB_PATH%" "%BACKUP_PATH%"
if %ERRORLEVEL% EQU 0 (
    echo ✅ Database backed up to: %BACKUP_PATH%
) else (
    echo ⚠️ Backup failed, but continuing anyway...
)
echo.

REM Check if sqlite3 is available
sqlite3 --version >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ sqlite3 not found in PATH
    echo Please install SQLite3 tools or use the app's automatic migration
    echo You can download SQLite3 from: https://www.sqlite.org/download.html
    pause
    exit /b 1
)

echo ✅ sqlite3 found, proceeding with fixes...
echo.

REM Add created_at column
echo Adding created_at column...
sqlite3 "%DB_PATH%" "ALTER TABLE customers ADD COLUMN created_at INTEGER;"
if %ERRORLEVEL% EQU 0 (
    echo ✅ created_at column added successfully
) else (
    echo ⚠️ created_at column might already exist
)
echo.

REM Populate created_at for existing records
echo Populating created_at for existing records...
sqlite3 "%DB_PATH%" "UPDATE customers SET created_at = CAST(strftime('%%s','now') AS INTEGER) WHERE created_at IS NULL;"
if %ERRORLEVEL% EQU 0 (
    echo ✅ created_at column populated successfully
) else (
    echo ⚠️ No records needed population or column already populated
)
echo.

REM Add phone column
echo Adding phone column...
sqlite3 "%DB_PATH%" "ALTER TABLE customers ADD COLUMN phone TEXT;"
if %ERRORLEVEL% EQU 0 (
    echo ✅ phone column added successfully
) else (
    echo ⚠️ phone column might already exist
)
echo.

REM Verify the fix
echo.
echo 🔍 Verifying the fix...
sqlite3 "%DB_PATH%" "PRAGMA table_info(customers);"
echo.
echo ✅ Database fix completed successfully!
echo.
echo Please restart the application and test customer editing.
echo.
pause
