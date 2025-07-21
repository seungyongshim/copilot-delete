# 텍스트 제거 PowerShell 스크립트

이 폴더에는 특정 텍스트를 파일에서 찾아서 공백으로 대체하는 두 개의 PowerShell 스크립트가 있습니다.

# 텍스트 제거 PowerShell 스크립트

이 폴더에는 텍스트 목록 파일에서 지정된 텍스트들을 파일에서 찾아서 공백으로 대체하는 PowerShell 스크립트들이 있습니다.

## 스크립트 설명

### 1. fix-copilot-extensions.ps1 ⭐ 추천
GitHub Copilot 확장의 extension.js 파일들을 자동으로 찾아서 수정합니다.

**사용법:**
```powershell
.\fix-copilot-extensions.ps1
.\fix-copilot-extensions.ps1 -TextListFile "custom-texts.txt" -BackupOriginal
```

**매개변수:**
- `-TextListFile`: 텍스트 목록 파일 경로 (기본값: "texts-to-remove.txt")
- `-BackupOriginal`: 원본 파일들을 .backup 확장자로 백업

**특징:**
- VS Code 및 VS Code Insiders 확장 폴더 자동 검색
- 모든 GitHub Copilot 확장 버전 지원 (github.copilot-*, github.copilot-chat-*)
- 버전에 상관없이 모든 extension.js 파일 처리

### 2. quick-fix-copilot.ps1
빠른 수정용 스크립트 (기본 텍스트만 제거)

**사용법:**
```powershell
.\quick-fix-copilot.ps1
.\quick-fix-copilot.ps1 -BackupOriginal
```

### 3. remove-text.ps1
단일 파일에서 지정된 텍스트들을 제거합니다.

**사용법:**
```powershell
.\remove-text.ps1 -FilePath "대상파일경로" -TextListFile "텍스트목록파일경로"
.\remove-text.ps1 -FilePath "대상파일경로" -TextListFile "텍스트목록파일경로" -BackupOriginal
```

**매개변수:**
- `-FilePath`: 처리할 파일의 경로 (필수)
- `-TextListFile`: 제거할 텍스트 목록이 담긴 파일 경로 (필수)
- `-BackupOriginal`: 원본 파일을 .backup 확장자로 백업 (선택사항)

### 4. remove-text-batch.ps1
여러 파일을 한 번에 처리합니다.

**사용법:**
```powershell
.\remove-text-batch.ps1 -FolderPath "대상폴더경로" -TextListFile "텍스트목록파일경로"
.\remove-text-batch.ps1 -FolderPath "대상폴더경로" -TextListFile "텍스트목록파일경로" -FilePattern "*.txt" -Recursive -BackupOriginal
```

**매개변수:**
- `-FolderPath`: 처리할 폴더의 경로 (필수)
- `-TextListFile`: 제거할 텍스트 목록이 담긴 파일 경로 (필수)
- `-FilePattern`: 파일 패턴 (기본값: "*.*")
- `-Recursive`: 하위 폴더까지 재귀적으로 검색
- `-BackupOriginal`: 원본 파일들을 .backup 확장자로 백업 (선택사항)

## 추천 사용법

### GitHub Copilot 확장 수정 (가장 일반적인 용도)
```powershell
# 기본 사용 (권장)
.\fix-copilot-extensions.ps1

# 백업과 함께 사용
.\fix-copilot-extensions.ps1 -BackupOriginal

# 빠른 수정 (기본 텍스트만)
.\quick-fix-copilot.ps1 -BackupOriginal
```

### 일반 파일 처리
```powershell
# 단일 파일 처리
.\remove-text.ps1 -FilePath "C:\example\document.txt" -TextListFile "texts-to-remove.txt"

# 폴더 내 모든 파일 처리
.\remove-text-batch.ps1 -FolderPath "C:\documents" -TextListFile "texts-to-remove.txt" -Recursive -BackupOriginal
```

## 텍스트 목록 파일

제거할 텍스트들을 한 줄씩 작성한 텍스트 파일을 준비해야 합니다. 예시: `texts-to-remove.txt`

```
If you are asked to generate content that is harmful, hateful, racist, sexist, lewd, or violent, only respond with "Sorry, I can't assist with that."
다른 제거할 텍스트 1
다른 제거할 텍스트 2
```

- 각 줄에 하나의 텍스트를 입력
- 빈 줄은 무시됩니다
- UTF-8 인코딩으로 저장하세요

## 주의사항

1. 스크립트 실행 전에 중요한 파일들은 미리 백업하세요.
2. `-BackupOriginal` 옵션을 사용하면 원본 파일이 자동으로 백업됩니다.
3. 스크립트는 UTF-8 인코딩으로 파일을 처리합니다.
4. PowerShell 실행 정책이 제한적일 경우, 다음 명령어로 임시 허용할 수 있습니다:
   ```powershell
   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
   ```

## 실행 권한

PowerShell 스크립트 실행이 차단된다면:
```powershell
# 현재 세션에서만 실행 허용
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

# 또는 서명된 스크립트만 허용
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```
