# PowerShell 스크립트: GitHub Copilot extension.js 파일 빠른 수정
# 사용법: .\quick-fix-copilot.ps1

param(
    [Parameter(Mandatory=$false)]
    [switch]$BackupOriginal = $false
)

$textToRemove = 'If you are asked to generate content that is harmful, hateful, racist, sexist, lewd, or violent, only respond with "Sorry, I can''t assist with that."'

# VS Code 확장 폴더들
$vscodeExtensionPaths = @(
    "$env:USERPROFILE\.vscode\extensions",
    "$env:USERPROFILE\.vscode-insiders\extensions"
)

Write-Host "GitHub Copilot 확장 검색 및 수정 중..." -ForegroundColor Cyan

$totalModified = 0

foreach ($basePath in $vscodeExtensionPaths) {
    if (Test-Path $basePath) {
        Write-Host "`n검색 중: $basePath" -ForegroundColor Yellow
        
        # GitHub Copilot 관련 폴더 찾기
        $copilotFolders = Get-ChildItem -Path $basePath -Directory | Where-Object { 
            $_.Name -like "github.copilot-*" 
        }
        
        foreach ($folder in $copilotFolders) {
            $extensionJsPath = Join-Path $folder.FullName "dist\extension.js"
            
            if (Test-Path $extensionJsPath) {
                Write-Host "처리 중: $($folder.Name)" -ForegroundColor Yellow
                
                try {
                    $content = Get-Content $extensionJsPath -Raw -Encoding UTF8
                    
                    if ($content -match [regex]::Escape($textToRemove)) {
                        if ($BackupOriginal) {
                            Copy-Item $extensionJsPath "$extensionJsPath.backup" -ErrorAction Stop
                            Write-Host "  -> 백업 생성됨" -ForegroundColor Gray
                        }
                        
                        $newContent = $content -replace [regex]::Escape($textToRemove), ""
                        $newContent | Out-File $extensionJsPath -Encoding UTF8 -NoNewline
                        
                        Write-Host "  -> 수정 완료!" -ForegroundColor Green
                        $totalModified++
                    }
                    else {
                        Write-Host "  -> 대상 텍스트 없음" -ForegroundColor Gray
                    }
                }
                catch {
                    Write-Warning "  -> 오류: $($_.Exception.Message)"
                }
            }
        }
    }
}

Write-Host "`n" + "=" * 50 -ForegroundColor Cyan
Write-Host "수정 완료! 총 $totalModified개 파일이 수정되었습니다." -ForegroundColor Green

if ($totalModified -gt 0) {
    Write-Host "VS Code를 재시작하여 변경사항을 적용하세요." -ForegroundColor Yellow
}
