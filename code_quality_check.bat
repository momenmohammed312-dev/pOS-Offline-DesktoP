@echo off
echo ========================================
echo POS System Code Quality Check
echo ========================================
echo.

echo Running Flutter Analyzer...
flutter analyze --no-fatal-infos

echo.
echo Checking for common issues...
echo.

REM Check for deprecated withOpacity usage
echo Checking for deprecated withOpacity() calls...
findstr /R /S /M:"*.dart" "withOpacity" lib\ | findstr /V "withValues"

echo.
echo Checking for missing super.key...
findstr /R /S /M:"*.dart" "const.*({" lib\ | findstr /V "super.key"

echo.
echo Checking for print statements...
findstr /R /S /M:"*.dart" "print(" lib\

echo.
echo ========================================
echo Code Quality Check Complete
echo ========================================
echo.
echo Review the output above for any issues.
echo Refer to DEVELOPMENT_GUIDELINES.md for fixes.
echo.
pause
