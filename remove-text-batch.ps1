# PowerShell 스크립트: 여러 파일에서 특정 텍스트를 공백으로 대체
# 사용법: .\remove-text-batch.ps1 -FolderPath "대상폴더경로" -TextListFile "텍스트목록파일경로" [-FilePattern "*.txt"] [-Recursive] [-BackupOriginal]

param(
    [Parameter(Mandatory=$true)]
    [string]$FolderPath,
    
    [Parameter(Mandatory=$true)]
    [string]$TextListFile,
    
    [Parameter(Mandatory=$false)]
    [string]$FilePattern = "*.*",
    
    [Parameter(Mandatory=$false)]
    [switch]$Recursive = $false,
    
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

# 폴더 존재 확인
if (-not (Test-Path $FolderPath)) {
    Write-Error "폴더를 찾을 수 없습니다: $FolderPath"
    exit 1
}

# 파일 검색 옵션 설정
$searchOptions = @{
    Path = $FolderPath
    Filter = $FilePattern
}

if ($Recursive) {
    $searchOptions.Add('Recurse', $true)
}

try {
    # 대상 파일들 찾기
    $files = Get-ChildItem @searchOptions | Where-Object { -not $_.PSIsContainer }
    
    if ($files.Count -eq 0) {
        Write-Host "조건에 맞는 파일을 찾을 수 없습니다." -ForegroundColor Yellow
        exit 0
    }
    
    Write-Host "총 $($files.Count)개의 파일을 검사합니다..." -ForegroundColor Cyan
    
    $processedCount = 0
    $modifiedCount = 0
    
    foreach ($file in $files) {
        $processedCount++
        Write-Host "[$processedCount/$($files.Count)] 처리 중: $($file.Name)" -ForegroundColor Yellow
        
        try {
            # 파일 내용 읽기
            $content = Get-Content $file.FullName -Raw -Encoding UTF8 -ErrorAction Stop
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
                    $backupPath = "$($file.FullName).backup"
                    Copy-Item $file.FullName $backupPath
                    Write-Host "  -> 백업 생성: $($file.Name).backup" -ForegroundColor Gray
                }
                
                # 파일에 쓰기
                $content | Out-File $file.FullName -Encoding UTF8 -NoNewline
                
                Write-Host "  -> 파일 수정 완료!" -ForegroundColor Green
                $modifiedCount++
            }
            else {
                Write-Host "  -> 대상 텍스트 없음" -ForegroundColor Gray
            }
        }
        catch {
            Write-Warning "  -> 오류: $($_.Exception.Message)"
        }
    }
    
    Write-Host "`n작업 완료!" -ForegroundColor Cyan
    Write-Host "처리된 파일: $processedCount개" -ForegroundColor White
    Write-Host "수정된 파일: $modifiedCount개" -ForegroundColor Green
}
catch {
    Write-Error "오류 발생: $($_.Exception.Message)"
    exit 1
}
