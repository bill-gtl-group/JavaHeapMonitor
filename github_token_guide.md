# GitHub Personal Access Token Guide

## Finding Your Existing Tokens

If you've previously created a GitHub Personal Access Token:

1. Sign in to GitHub
2. Click on your profile picture in the top-right corner
3. Select "Settings"
4. In the left sidebar, click on "Developer settings"
5. Click on "Personal access tokens" and then "Tokens (classic)"
6. You'll see a list of your existing tokens

**Note:** For security reasons, GitHub doesn't display the full token after it's been created. If you can't find your token, you'll need to create a new one.

## Creating a New Token

1. Sign in to GitHub
2. Click on your profile picture in the top-right corner
3. Select "Settings"
4. In the left sidebar, click on "Developer settings"
5. Click on "Personal access tokens" and then "Tokens (classic)"
6. Click "Generate new token" and then "Generate new token (classic)"
7. Give your token a descriptive name (e.g., "Java Heap Monitor")
8. Set an expiration date (or select "No expiration" if needed)
9. Select the following scopes:
   - `repo` (Full control of private repositories)
10. Click "Generate token"
11. **IMPORTANT:** Copy the token immediately and store it securely. You won't be able to see it again!

## Using Your Token

When prompted by the `push_to_github.bat` script:

1. Enter your GitHub username (e.g., "bill-gtl-group")
2. Paste your Personal Access Token when prompted for the token
3. The script will use this token to create a repository and push your code

## Security Notes

- Treat your Personal Access Token like a password
- Don't share it with others
- If you suspect your token has been compromised, revoke it immediately and create a new one
- Consider setting an expiration date for your tokens
