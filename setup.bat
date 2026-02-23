@echo off
echo === Python Project Setup ===

REM 1. Create virtual environment if it doesn't exist
if not exist ".venv" (
    echo Creating virtual environment...
    python -m venv .venv
    echo Virtual environment created!
) else (
    echo Virtual environment already exists.
)

REM Activate virtual environment
call .venv\Scripts\activate.bat

REM 2. Install dependencies from requirements.txt
if exist "requirements.txt" (
    echo Installing dependencies from requirements.txt...
    pip install -r requirements.txt
    echo Dependencies installed!
) else (
    echo No requirements.txt found, skipping dependency installation.
)

REM 3. Install pre-commit hooks if not already installed
if exist ".pre-commit-config.yaml" (
    if not exist ".git\hooks\pre-commit" (
        echo Installing pre-commit hooks...
        pre-commit install --install-hooks
        echo Pre-commit hooks installed!
    ) else (
        echo Pre-commit hooks already installed.
    )
) else (
    echo No .pre-commit-config.yaml found, skipping pre-commit setup.
)

echo.
echo === Setup Complete! ===
echo Virtual environment is activated and ready to use.
pause