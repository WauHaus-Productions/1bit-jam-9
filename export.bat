@echo off
echo Exporting Godot project to Web...
"C:\Users\Oscar\Desktop\godot\Godot_v4.6.1-stable_win64.exe" --headless --export-release "Web" build/unzipped/index.html

echo.
echo Zipping build/unzipped contents to build/game.zip...
powershell -Command "Compress-Archive -Path 'build\unzipped\*' -DestinationPath 'build\game.zip' -Force"

echo.
echo Done! Export and zip complete.
pause