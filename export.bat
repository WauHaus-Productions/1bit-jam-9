@echo off
setlocal

REM Default Godot engine path
set "DEFAULT_GODOT=C:\Users\Oscar\Desktop\godot\Godot_v4.6.1-stable_win64.exe"

REM Use provided argument or default
if "%~1"=="" (
    set "GODOT_PATH=%DEFAULT_GODOT%"
    echo Using default Godot engine path: %GODOT_PATH%
) else (
    set "GODOT_PATH=%~1"
    echo Using provided Godot engine path: %GODOT_PATH%
)

REM Check if the Godot executable exists
if not exist "%GODOT_PATH%" (
    echo ERROR: Godot executable not found at: %GODOT_PATH%
    echo Please provide a valid path to the Godot executable.
    exit /b 1
)

echo.
echo Exporting Godot project to Web...
"%GODOT_PATH%" --headless --export-release "Web" build/unzipped/index.html

if errorlevel 1 (
    echo ERROR: Export failed!
    exit /b 1
)

echo.
echo Zipping build/unzipped contents to build/game.zip...
powershell -Command "Compress-Archive -Path 'build\unzipped\*' -DestinationPath 'build\game.zip' -Force"

if errorlevel 1 (
    echo ERROR: Zipping failed!
    exit /b 1
)

echo.
echo Done! Export and zip complete.
pause