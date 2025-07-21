# PowerShell 스크립트: GitHub Copilot extension.js 파일들을 자동으로 찾아서 텍스트 제거
# 사용법: .\fix-copilot-extensions.ps1 [-TextListFile "텍스트목록파일경로"] [-BackupOriginal]

param(
    [Parameter(Mandatory=$false)]
    [string]$TextListFile = "texts-to-remove.txt",
    
    [Parameter(Mandatory=$false)]
    [switch]$BackupOriginal = $false
)

# 텍스트 목록 파일 존재 확인
if (-not (Test-Path $TextListFile)) {
    Write-Error "텍스트 목록 파일을 찾을 수 없습니다: $TextListFile"
    Write-Host "현재 디렉토리에 'texts-to-remove.txt' 파일을 생성하거나 -TextListFile 매개변수로 다른 파일을 지정하세요." -ForegroundColor Yellow
    exit 1
}

# 대체할 텍스트 목록을 파일에서 읽기
try {
    $textsToReplace = Get-Content $TextListFile -Encoding UTF8 | Where-Object { $_.Trim() -ne "" }
    if ($textsToReplace.Count -eq 0) {
        Write-Error "텍스트 목록 파일이 비어있거나 유효한 텍스트가 없습니다: $TextListFile"
        exit 1
    }
    Write-Host "텍스트 목록 파일에서 $($textsToReplace.Count)개의 텍스트를 읽었습니다." -ForegroundColor Cyan
}
catch {
    Write-Error "텍스트 목록 파일을 읽는 중 오류 발생: $($_.Exception.Message)"
    exit 1
}

# VS Code Insiders 및 VS Code 확장 폴더 경로들
$vscodeExtensionPaths = @(
    "$env:USERPROFILE\.vscode\extensions",
    "$env:USERPROFILE\.vscode-insiders\extensions"
)

# GitHub Copilot 확장 검색 패턴
$copilotPatterns = @(
    "github.copilot-*",
    "github.copilot-chat-*"
)

Write-Host "GitHub Copilot 확장 검색 중..." -ForegroundColor Cyan

$foundExtensions = @()

foreach ($basePath in $vscodeExtensionPaths) {
    if (Test-Path $basePath) {
        Write-Host "검색 중: $basePath" -ForegroundColor Yellow
        
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
                    Write-Host "  -> 발견: $extension" -ForegroundColor Green
                }
            }
        }
    }
    else {
        Write-Host "경로가 존재하지 않습니다: $basePath" -ForegroundColor Gray
    }
}

if ($foundExtensions.Count -eq 0) {
    Write-Host "GitHub Copilot 확장의 extension.js 파일을 찾을 수 없습니다." -ForegroundColor Red
    Write-Host "VS Code 또는 VS Code Insiders에 GitHub Copilot 확장이 설치되어 있는지 확인하세요." -ForegroundColor Yellow
    exit 0
}

Write-Host "`n총 $($foundExtensions.Count)개의 extension.js 파일을 찾았습니다." -ForegroundColor Cyan
Write-Host "처리를 시작합니다...`n" -ForegroundColor Cyan

$processedCount = 0
$modifiedCount = 0

foreach ($extension in $foundExtensions) {
    $processedCount++
    Write-Host "[$processedCount/$($foundExtensions.Count)] 처리 중: $($extension.Name)" -ForegroundColor Yellow
    Write-Host "  파일: $($extension.Path)" -ForegroundColor Gray
    
    try {
        # 파일 내용 읽기
        $content = Get-Content $extension.Path -Raw -Encoding UTF8 -ErrorAction Stop
        $originalContent = $content
        $fileModified = $false
        
        # 각 텍스트에 대해 순차적으로 처리
        foreach ($textToReplace in $textsToReplace) {
            if ($content -match [regex]::Escape($textToReplace)) {
                # 텍스트를 공백으로 대체
                $content = $content -replace [regex]::Escape($textToReplace), ""
                $fileModified = $true
                Write-Host "  -> 텍스트 제거: $(if($textToReplace.Length -gt 50) { $textToReplace.Substring(0,47) + "..." } else { $textToReplace })" -ForegroundColor Gray
            }
        }
        
        # 파일이 수정된 경우에만 저장
        if ($fileModified) {
            # 원본 파일 백업 (옵션)
            if ($BackupOriginal) {
                $backupPath = "$($extension.Path).backup"
                Copy-Item $extension.Path $backupPath -ErrorAction Stop
                Write-Host "  -> 백업 생성: extension.js.backup" -ForegroundColor Gray
            }
            
            # 파일에 쓰기
            $content | Out-File $extension.Path -Encoding UTF8 -NoNewline
            
            Write-Host "  -> 파일 수정 완료!" -ForegroundColor Green
            $modifiedCount++
        }
        else {
            Write-Host "  -> 대상 텍스트 없음" -ForegroundColor Gray
        }
    }
    catch {
        Write-Warning "  -> 오류: $($_.Exception.Message)"
        Write-Host "  -> 관리자 권한으로 실행하거나 VS Code를 종료 후 다시 시도하세요." -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "=" * 60 -ForegroundColor Cyan
Write-Host "작업 완료!" -ForegroundColor Cyan
Write-Host "처리된 파일: $processedCount개" -ForegroundColor White
Write-Host "수정된 파일: $modifiedCount개" -ForegroundColor Green

if ($modifiedCount -gt 0) {
    Write-Host "`n참고: VS Code 또는 VS Code Insiders를 재시작하여 변경사항을 적용하세요." -ForegroundColor Yellow
}
