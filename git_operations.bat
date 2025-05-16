@echo off
echo Java Heap Monitor - Git Operations

set GIT_TOOLS_DIR=C:\Develop\git_tools

echo Available Git operations:
echo 1. Push changes to GitHub
echo 2. Set up a new GitHub repository
echo 3. Create a GitHub repository automatically (requires GitHub token)
echo.

set /p choice=Enter your choice (1-3): 

if "%choice%"=="1" (
    echo Pushing changes to GitHub...
    call "%GIT_TOOLS_DIR%\push_to_github.bat"
) else if "%choice%"=="2" (
    echo Setting up a new GitHub repository...
    call "%GIT_TOOLS_DIR%\setup_github_repo.bat"
) else if "%choice%"=="3" (
    echo.
    echo To create a GitHub repository automatically, you need:
    echo - Your GitHub username
    echo - A Personal Access Token with 'repo' scope
    echo.
    echo For information on how to create a Personal Access Token, see:
    echo "%GIT_TOOLS_DIR%\github_token_guide.md"
    echo.
    
    set /p username=Enter your GitHub username: 
    set /p token=Enter your Personal Access Token: 
    
    powershell -ExecutionPolicy Bypass -File "%GIT_TOOLS_DIR%\create_github_repo.ps1" -GitHubUsername "%username%" -PersonalAccessToken "%token%"
) else (
    echo Invalid choice. Please run the script again and select a valid option.
)

echo.
echo Operation completed.
pause
