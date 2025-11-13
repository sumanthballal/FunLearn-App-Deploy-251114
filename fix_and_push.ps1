# fix_and_push.ps1
# Usage: open PowerShell in the repository root and run: .\fix_and_push.ps1
# This script:
#  - sets local git user.name and user.email (repo-local)
#  - ensures remote 'origin' matches the repo URL
#  - stages all changes, commits if there are changes, and pushes main

$email   = '242165576+sumanthballal@users.noreply.github.com'
$user    = 'Sumanth Ballal'
$repoUrl = 'https://github.com/sumanthballal/FunLearn.git'
$branch  = 'main'

function FailAndExit($msg) {
    Write-Error $msg
    exit 1
}

Write-Host "1) Checking for git repository..."
$inside = & git rev-parse --is-inside-work-tree 2>$null
if ($LASTEXITCODE -ne 0 -or $inside -ne 'true') {
    FailAndExit "This folder is not a git repository. Run this script from the repo root."
}

Write-Host "2) Setting local git user.name and user.email..."
& git config user.name "$user"
if ($LASTEXITCODE -ne 0) { Write-Warning "Failed to set user.name"; }
& git config user.email "$email"
if ($LASTEXITCODE -ne 0) { Write-Warning "Failed to set user.email"; }

Write-Host "3) Ensure remote 'origin' is set to: $repoUrl"
$existing = & git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0) {
    if ($existing -ne $repoUrl) {
        Write-Host "Remote 'origin' currently: $existing"
        Write-Host "Updating 'origin' to $repoUrl..."
        & git remote set-url origin $repoUrl
        if ($LASTEXITCODE -ne 0) { Write-Warning "Failed to update origin URL."; }
        else { Write-Host "Updated origin." }
    } else {
        Write-Host "Remote 'origin' already correct."
    }
} else {
    Write-Host "Remote 'origin' does not exist — adding it..."
    & git remote add origin $repoUrl
    if ($LASTEXITCODE -ne 0) { Write-Warning "Failed to add origin."; }
    else { Write-Host "Added origin." }
}

Write-Host "4) Staging all changes..."
& git add -A
if ($LASTEXITCODE -ne 0) { FailAndExit "git add failed."; }

# Check for anything to commit
$status = & git status --porcelain
if ([string]::IsNullOrWhiteSpace($status)) {
    Write-Host "No changes to commit."
} else {
    $message = "Auto commit from fix_and_push.ps1 - $(Get-Date -Format u)"
    Write-Host "Committing changes: $message"
    & git commit -m $message
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "git commit failed. You may need to set user.name globally or resolve conflicts."
    } else {
        Write-Host "Committed changes."
    }
}

Write-Host "5) Pushing to origin/$branch..."
# Try normal push
& git push origin $branch
if ($LASTEXITCODE -eq 0) {
    Write-Host "Push successful ✅"
    exit 0
}

Write-Warning "Initial push failed. Capturing push output for diagnosis..."
$pushOutput = & git push origin $branch 2>&1

if ($pushOutput -match "GH007|publish a private email|email") {
    Write-Host "Detected GitHub email privacy rejection (GH007)."
    Write-Host "Double-check that the email $email is listed in your GitHub account Settings → Emails."
    Write-Host "Or disable 'Block command line pushes that expose my email' in GitHub email settings."
    Write-Host "If you just added the email on GitHub, wait a minute and try again."
    exit 1
}

if ($pushOutput -match "non-fast-forward|rejected") {
    Write-Host "Push rejected (non-fast-forward). Attempting git pull --rebase..."
    & git pull --rebase origin $branch
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Pull --rebase failed. Resolve conflicts manually, then re-run this script."
        Write-Host "Conflicts may require: git status, edit files, git add <file>, git rebase --continue"
        exit 1
    } else {
        Write-Host "Rebase successful. Trying push again..."
        & git push origin $branch
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Push successful after rebase ✅"
            exit 0
        } else {
            Write-Error "Push still failed after rebase. Output:"
            Write-Host $pushOutput
            exit 1
        }
    }
}

Write-Error "Push failed for an unknown reason. Output:"
Write-Host $pushOutput
exit 1
