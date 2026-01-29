@echo off
echo Running build_runner to generate missing files...
flutter pub run build_runner build --delete-conflicting-outputs
echo Build runner completed!
pause
