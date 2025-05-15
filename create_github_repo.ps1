# PowerShell script to create a GitHub repository and push the Java Heap Monitor project
# This script requires a GitHub Personal Access Token with 'repo' scope

param (
    [Parameter(Mandatory=$true)]
    [string]$GitHubUsername,
    
    [Parameter(Mandatory=$true)]
    [string]$PersonalAccessToken,
    
    [Parameter(Mandatory=$false)]
    [string]$RepoName = "JavaHeapMonitor",
    
    [Parameter(Mandatory=$false)]
    [string]$RepoDescription = "Java Heap Memory Monitor with alert functionality",
    
    [Parameter(Mandatory=$false)]
    [bool]$Private = $false
)

# Set the current directory to the script's directory
Set-Location -Path $PSScriptRoot

# Function to check if Git is installed
function Test-GitInstalled {
    try {
        $null = git --version
        return $true
    } catch {
        return $false
    }
}

# Function to create a GitHub repository
function New-GitHubRepository {
    param (
        [string]$Username,
        [string]$Token,
        [string]$RepoName,
        [string]$Description,
        [bool]$Private
    )
    
    $auth = [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes("$($Username):$($Token)"))
    $headers = @{
        Authorization = "Basic $auth"
        Accept = "application/vnd.github.v3+json"
    }
    
    $body = @{
        name = $RepoName
        description = $Description
        private = $Private
        auto_init = $false
    } | ConvertTo-Json
    
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/user/repos" -Method Post -Headers $headers -Body $body -ContentType "application/json"
        return $response.html_url
    } catch {
        Write-Error "Failed to create GitHub repository: $_"
        return $null
    }
}

# Check if Git is installed
if (-not (Test-GitInstalled)) {
    Write-Error "Git is not installed or not in the PATH. Please install Git and try again."
    exit 1
}

# Create GitHub repository
Write-Host "Creating GitHub repository '$RepoName'..."
$repoUrl = New-GitHubRepository -Username $GitHubUsername -Token $PersonalAccessToken -RepoName $RepoName -Description $RepoDescription -Private $Private

if (-not $repoUrl) {
    Write-Error "Failed to create GitHub repository. Exiting."
    exit 1
}

Write-Host "GitHub repository created successfully: $repoUrl"

# Initialize Git repository if not already initialized
if (-not (Test-Path -Path ".git")) {
    Write-Host "Initializing Git repository..."
    git init
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Failed to initialize Git repository."
        exit 1
    }
}

# Add all files to Git
Write-Host "Adding files to Git..."
git add .
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to add files to Git."
    exit 1
}

# Create initial commit
Write-Host "Creating initial commit..."
git commit -m "Initial commit: Java Heap Monitor with configuration file and alert improvements"
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to create initial commit."
    exit 1
}

# Add remote and push
Write-Host "Adding remote repository..."
$remoteUrl = "https://$($GitHubUsername):$($PersonalAccessToken)@github.com/$($GitHubUsername)/$($RepoName).git"
git remote add origin $remoteUrl
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to add remote repository."
    exit 1
}

Write-Host "Setting main branch..."
git branch -M main
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to set main branch."
    exit 1
}

Write-Host "Pushing to GitHub..."
git push -u origin main
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to push to GitHub."
    exit 1
}

Write-Host "Successfully pushed Java Heap Monitor to GitHub: $repoUrl"
Write-Host "You can clone this repository using: git clone $repoUrl"
