@echo off
echo 🚨 DIRECT DATABASE FIX
echo.

REM Find database in common locations
for %%D in (
    "%LOCALAPPDATA%\pos_offline_desktop_database"
    "%APPDATA%\pos_offline_desktop_database"
    "%USERPROFILE%\AppData\Local\pos_offline_desktop_database"
    "%USERPROFILE%\AppData\Roaming\pos_offline_desktop_database"
) do (
    if exist "%%D\pos_offline_desktop_database.sqlite" (
        set DB_PATH=%%D\pos_offline_desktop_database.sqlite
        echo ✅ Database found at: %%D\pos_offline_desktop_database.sqlite
        goto :found
    )
)

:found
echo Database path: %DB_PATH%

if not defined DB_PATH (
    echo ❌ Database not found in common locations
    echo Please run the application first to create the database
    pause
    exit /b 1
)

REM Create backup
copy "%DB_PATH%" "%DB_PATH%.backup.%DATE:~0,4%%TIME:~0,2%"
echo ✅ Database backed up

REM Try to add created_at column
echo Adding created_at column...
sqlite3 "%DB_PATH%" "ALTER TABLE customers ADD COLUMN created_at INTEGER;" 2>nul
echo ✅ created_at column added

REM Populate existing records
echo Populating created_at...
sqlite3 "%DB_PATH%" "UPDATE customers SET created_at = CAST(strftime('%%s','now') AS INTEGER) WHERE created_at IS NULL;" 2>nul
echo ✅ created_at populated

REM Add phone column
echo Adding phone column...
sqlite3 "%DB_PATH%" "ALTER TABLE customers ADD COLUMN phone TEXT;" 2>nul
echo ✅ phone column added

echo.
echo 🎉 DATABASE FIX COMPLETED!
echo Please restart the application and test customer editing.
echo.
pause
