# PowerShell Script: Automatically find and modify GitHub Copilot extension.js files
# Usage: .\fix-copilot-extensions-en.ps1 [-TextListFile "text-list-file-path"] [-BackupOriginal]

param(
    [Parameter(Mandatory=$false)]
    [string]$TextListFile = "texts-to-remove.txt",
    
    [Parameter(Mandatory=$false)]
    [switch]$BackupOriginal = $false
)

# Check if text list file exists
if (-not (Test-Path $TextListFile)) {
    Write-Error "Text list file not found: $TextListFile"
    Write-Host "Please create 'texts-to-remove.txt' file in current directory or specify different file with -TextListFile parameter." -ForegroundColor Yellow
    exit 1
}

# Read text list from file
try {
    $textsToReplace = Get-Content $TextListFile -Encoding UTF8 | Where-Object { $_.Trim() -ne "" }
    if ($textsToReplace.Count -eq 0) {
        Write-Error "Text list file is empty or contains no valid text: $TextListFile"
        exit 1
    }
    Write-Host "Read $($textsToReplace.Count) text(s) from text list file." -ForegroundColor Cyan
}
catch {
    Write-Error "Error reading text list file: $($_.Exception.Message)"
    exit 1
}

# VS Code Insiders and VS Code extension folder paths
$vscodeExtensionPaths = @(
    "$env:USERPROFILE\.vscode\extensions",
    "$env:USERPROFILE\.vscode-insiders\extensions"
)

# GitHub Copilot extension search patterns
$copilotPatterns = @(
    "github.copilot-*",
    "github.copilot-chat-*"
)

Write-Host "Searching for GitHub Copilot extensions..." -ForegroundColor Cyan

$foundExtensions = @()

foreach ($basePath in $vscodeExtensionPaths) {
    if (Test-Path $basePath) {
        Write-Host "Searching in: $basePath" -ForegroundColor Yellow
        
        foreach ($pattern in $copilotPatterns) {
            $extensions = Get-ChildItem -Path $basePath -Directory -Name $pattern -ErrorAction SilentlyContinue
            foreach ($extension in $extensions) {
                $extensionPath = Join-Path $basePath $extension
                $extensionJsPath = Join-Path $extensionPath "dist\extension.js"
                
                if (Test-Path $extensionJsPath) {
                    $foundExtensions += @{
                        Name = $extension
                        Path = $extensionJsPath
                    }
                    Write-Host "  -> Found: $extension" -ForegroundColor Green
                }
            }
        }
    }
    else {
        Write-Host "Path does not exist: $basePath" -ForegroundColor Gray
    }
}

if ($foundExtensions.Count -eq 0) {
    Write-Host "No GitHub Copilot extension.js files found." -ForegroundColor Red
    Write-Host "Please make sure GitHub Copilot extension is installed in VS Code or VS Code Insiders." -ForegroundColor Yellow
    exit 0
}

Write-Host "`nFound total $($foundExtensions.Count) extension.js file(s)." -ForegroundColor Cyan
Write-Host "Starting processing...`n" -ForegroundColor Cyan

$processedCount = 0
$modifiedCount = 0

foreach ($extension in $foundExtensions) {
    $processedCount++
    Write-Host "[$processedCount/$($foundExtensions.Count)] Processing: $($extension.Name)" -ForegroundColor Yellow
    Write-Host "  File: $($extension.Path)" -ForegroundColor Gray
    
    try {
        # Read file content
        $content = Get-Content $extension.Path -Raw -Encoding UTF8 -ErrorAction Stop
        $originalContent = $content
        $fileModified = $false
        
        # Process each text from file sequentially (remove texts)
        foreach ($textToReplace in $textsToReplace) {
            if ($content -match [regex]::Escape($textToReplace)) {
                # Replace text with empty string
                $content = $content -replace [regex]::Escape($textToReplace), ""
                $fileModified = $true
                Write-Host "  -> Text removed: $(if($textToReplace.Length -gt 50) { $textToReplace.Substring(0,47) + "..." } else { $textToReplace })" -ForegroundColor Gray
            }
        }
        
        # Save only if file was modified
        if ($fileModified) {
            # Backup original file (optional)
            if ($BackupOriginal) {
                $backupPath = "$($extension.Path).backup"
                Copy-Item $extension.Path $backupPath -ErrorAction Stop
                Write-Host "  -> Backup created: extension.js.backup" -ForegroundColor Gray
            }
            
            # Write to file
            $content | Out-File $extension.Path -Encoding UTF8 -NoNewline
            
            Write-Host "  -> File modification completed!" -ForegroundColor Green
            $modifiedCount++
        }
        else {
            Write-Host "  -> No target text found" -ForegroundColor Gray
        }
    }
    catch {
        Write-Warning "  -> Error: $($_.Exception.Message)"
        Write-Host "  -> Try running as administrator or close VS Code and try again." -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "Processing completed!" -ForegroundColor Cyan
Write-Host "Processed files: $processedCount" -ForegroundColor White
Write-Host "Modified files: $modifiedCount" -ForegroundColor Green

if ($modifiedCount -gt 0) {
    Write-Host "`nNote: Please restart VS Code or VS Code Insiders to apply changes." -ForegroundColor Yellow
}
