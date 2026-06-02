# TodoLift (todo-app)

Flutter 기반 Android 할일 잠금화면 알림 앱.

- 패키지: `com.onethelab.todolift`
- 앱 이름: TodoLift

## 보안 — 키스토어 / 서명 (중요)

다음 파일은 **절대 git에 커밋하지 않는다.**

- `android/key.properties` — 서명 설정(비밀번호 포함)
- `android/todolift-upload.jks` — 업로드 키스토어 본체

원본 백업: `C:\Users\gunug\Downloads\todolift-upload.jks`

| 항목 | 값 |
|------|-----|
| keyAlias | `todolift-upload` |
| storeFile | `../android/todolift-upload.jks` |
| storePassword / keyPassword | (key.properties 참조) |

## AAB 빌드 워크플로 (중요)

### 1. 빌드 전 — 버전 결정 (필수)

#### versionCode (`+N`) — 무조건 +1
- **동일한 versionCode로는 절대 빌드하지 않는다.**
- Play Console 현재 최신 versionCode 확인 후 +1:
  ```
  python C:\Users\gunug\check_todolift.py
  ```
- `pubspec.yaml`의 `version` 필드에서 `+N` 부분을 올린다.

#### versionName — 변경 내용에 따라 결정
빌드 전에 사용자에게 versionName 변경 여부를 확인한다. 아무 말이 없으면 유지.

| 상황 | 변경 |
|---|---|
| 버그 수정, 소규모 개선 | patch +1 (1.0.0 → 1.0.1) |
| 새 기능 추가, 동작 변경 | minor +1 (1.0.0 → 1.1.0) |
| 전면 재설계, 비호환 변경 | major +1 (1.0.0 → 2.0.0) |

### 2. 빌드

```
flutter build appbundle --release
```

출력: `build\app\outputs\bundle\release\app-release.aab`

### 3. Play Console 내부 테스트 자동 출시

빌드가 끝나면 Python 스크립트로 직접 출시한다.

#### 인증 정보
- **서비스 계정 키**: `C:\Users\gunug\Downloads\effortless-launcher-e202f6c046c1.json`
- **패키지**: `com.onethelab.todolift`

#### 업로드 스크립트

```python
import socket
socket.setdefaulttimeout(600)

from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload
from google.oauth2 import service_account

KEY_FILE = r"C:\Users\gunug\Downloads\effortless-launcher-e202f6c046c1.json"
PACKAGE  = "com.onethelab.todolift"
AAB_PATH = r"C:\Users\gunug\OneDrive - OneTheLab\00_project\todo-app\build\app\outputs\bundle\release\app-release.aab"
TRACK    = "internal"
KO_NOTES = "<한국어 출시 노트>"
EN_NOTES = "<English release notes>"

SCOPES = ["https://www.googleapis.com/auth/androidpublisher"]
creds  = service_account.Credentials.from_service_account_file(KEY_FILE, scopes=SCOPES)
service = build("androidpublisher", "v3", credentials=creds)

edit    = service.edits().insert(packageName=PACKAGE, body={}).execute()
edit_id = edit["id"]

media  = MediaFileUpload(AAB_PATH, mimetype="application/octet-stream", resumable=True, chunksize=5*1024*1024)
bundle = service.edits().bundles().upload(packageName=PACKAGE, editId=edit_id, media_body=media).execute(num_retries=5)

service.edits().tracks().update(
    packageName=PACKAGE, editId=edit_id, track=TRACK,
    body={"track": TRACK, "releases": [{"status": "completed",
        "versionCodes": [str(bundle["versionCode"])],
        "releaseNotes": [{"language": "ko-KR", "text": KO_NOTES},
                         {"language": "en-US", "text": EN_NOTES}]}]}
).execute()

service.edits().commit(packageName=PACKAGE, editId=edit_id).execute()
print(f"Done! versionCode {bundle['versionCode']} -> internal track")
```

스크립트 파일: `C:\Users\gunug\upload_todolift.py` (이미 존재)

#### versionCode 확인 스크립트
스크립트 파일: `C:\Users\gunug\check_todolift.py` (이미 존재)

#### 절차 요약
1. `python C:\Users\gunug\check_todolift.py` 로 현재 최대 versionCode 확인
2. `pubspec.yaml` versionCode +1, versionName 필요 시 변경
3. `flutter build appbundle --release`
4. `upload_todolift.py`의 KO_NOTES, EN_NOTES 채운 뒤 실행
