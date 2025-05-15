@echo off
echo Setting up Git repository for Java Heap Monitor...

REM Initialize Git repository
echo Initializing Git repository...
cd /d "%~dp0"
git init
if %errorlevel% neq 0 (
    echo Failed to initialize Git repository.
    pause
    exit /b 1
)

REM Add all files to Git
echo Adding files to Git...
git add .
if %errorlevel% neq 0 (
    echo Failed to add files to Git.
    pause
    exit /b 1
)

REM Create initial commit
echo Creating initial commit...
git commit -m "Initial commit: Java Heap Monitor with configuration file and alert improvements"
if %errorlevel% neq 0 (
    echo Failed to create initial commit.
    pause
    exit /b 1
)

echo.
echo Git repository initialized successfully!
echo.
echo =====================================================================
echo NEXT STEPS TO PUSH TO GITHUB:
echo =====================================================================
echo.
echo 1. Create a new repository on GitHub:
echo    - Go to https://github.com/new
echo    - Enter "JavaHeapMonitor" as the repository name
echo    - Add a description: "Java Heap Memory Monitor with alert functionality"
echo    - Choose public or private visibility
echo    - Click "Create repository"
echo.
echo 2. Connect and push to GitHub (copy and paste these commands):
echo    git remote add origin https://github.com/YOUR_USERNAME/JavaHeapMonitor.git
echo    git branch -M main
echo    git push -u origin main
echo.
echo Replace YOUR_USERNAME with your GitHub username
echo =====================================================================
echo.
pause
