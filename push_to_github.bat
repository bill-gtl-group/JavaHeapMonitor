@echo off
echo Java Heap Monitor - GitHub Repository Setup

echo.
echo This script will help you create a GitHub repository for the Java Heap Monitor project.
echo.
echo Choose an option:
echo 1. Initialize Git repository and get manual instructions (Recommended for beginners)
echo 2. Use PowerShell script to automatically create and push to GitHub (Requires GitHub token)
echo.

set /p choice="Enter your choice (1 or 2): "

if "%choice%"=="1" (
    echo.
    echo Running setup_github_repo.bat...
    call setup_github_repo.bat
) else if "%choice%"=="2" (
    echo.
    echo Running PowerShell script...
    echo.
    set /p username="Enter your GitHub username: "
    set /p token="Enter your GitHub Personal Access Token: "
    
    powershell -ExecutionPolicy Bypass -File "create_github_repo.ps1" -GitHubUsername "%username%" -PersonalAccessToken "%token%"
) else (
    echo.
    echo Invalid choice. Please run the script again and select 1 or 2.
    pause
    exit /b 1
)

echo.
echo Done!
pause
