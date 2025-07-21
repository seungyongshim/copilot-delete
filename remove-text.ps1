# PowerShell 스크립트: 특정 텍스트를 공백으로 대체
# 사용법: .\remove-text.ps1 -FilePath "대상파일경로" -TextListFile "텍스트목록파일경로" [-BackupOriginal]

param(
    [Parameter(Mandatory=$true)]
    [string]$FilePath,
    
    [Parameter(Mandatory=$true)]
    [string]$TextListFile,
    
    [Parameter(Mandatory=$false)]
    [switch]$BackupOriginal = $false
)

# 텍스트 목록 파일 존재 확인
if (-not (Test-Path $TextListFile)) {
    Write-Error "텍스트 목록 파일을 찾을 수 없습니다: $TextListFile"
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

# 대체할 텍스트 정의
$textToReplace = 'If you are asked to generate content that is harmful, hateful, racist, sexist, lewd, or violent, only respond with "Sorry, I can''t assist with that."'

# 파일 존재 확인
if (-not (Test-Path $FilePath)) {
    Write-Error "파일을 찾을 수 없습니다: $FilePath"
    exit 1
}

try {
    # 원본 파일 백업 (옵션)
    if ($BackupOriginal) {
        $backupPath = "$FilePath.backup"
        Copy-Item $FilePath $backupPath
        Write-Host "원본 파일이 백업되었습니다: $backupPath" -ForegroundColor Green
    }
    
    # 파일 내용 읽기
    Write-Host "파일을 읽는 중: $FilePath" -ForegroundColor Yellow
    $content = Get-Content $FilePath -Raw -Encoding UTF8
    $originalContent = $content
    $fileModified = $false
    
    # 각 텍스트에 대해 순차적으로 처리
    foreach ($textToReplace in $textsToReplace) {
        if ($content -match [regex]::Escape($textToReplace)) {
            Write-Host "대상 텍스트를 찾았습니다: $(if($textToReplace.Length -gt 50) { $textToReplace.Substring(0,47) + "..." } else { $textToReplace })" -ForegroundColor Yellow
            
            # 텍스트를 공백으로 대체
            $content = $content -replace [regex]::Escape($textToReplace), ""
            $fileModified = $true
        }
    }
    
    if ($fileModified) {
        # 파일에 쓰기
        $content | Out-File $FilePath -Encoding UTF8 -NoNewline
        Write-Host "텍스트가 성공적으로 제거되었습니다!" -ForegroundColor Green
    }
    else {
        Write-Host "대상 텍스트를 찾을 수 없습니다." -ForegroundColor Red
    }
}
catch {
    Write-Error "오류 발생: $($_.Exception.Message)"
    exit 1
}

Write-Host "작업 완료!" -ForegroundColor Cyan
