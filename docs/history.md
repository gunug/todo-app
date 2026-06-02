# 버그 및 수정 이력

## 2026-06-02

### [BUG-1] 앱 실행 즉시 크래시
- **증상**: 업데이트 후 앱을 열면 즉시 종료됨
- **원인**: `build.gradle.kts`의 `namespace`를 `com.onethelab.todolift`로 변경했으나 `MainActivity.kt`는 `com/example/todo_lock_app/` 경로에 그대로 남아 있어 Android가 Activity 클래스를 찾지 못함
- **수정**: `MainActivity.kt`를 `com/onethelab/todolift/` 경로로 이동, 패키지 선언도 `com.onethelab.todolift`로 변경
- **규칙**: `namespace`(build.gradle.kts)를 바꾸면 `kotlin/` 하위 디렉토리 경로와 파일 내 `package` 선언도 반드시 함께 변경한다

---

### [BUG-2] 검은 화면에서 멈춤 (앱 삭제·재설치·캐시 삭제 후에도 동일)
- **증상**: 앱이 크래시 없이 실행되지만 검은 화면만 표시되고 UI가 나타나지 않음
- **원인**: `main()`에서 `notificationService.init()` 이 `runApp()` 앞에서 호출됨. `init()` 내부의 timezone 로딩(`tz.initializeTimeZones()`) 또는 `FlutterTimezone.getLocalTimezone()` 등이 블로킹하면 `runApp()`이 실행되지 않아 Flutter UI가 렌더링되지 않음
- **수정**:
  - `runApp()` 전에는 `HiveService.init()`만 실행
  - `notificationService.init()`, `requestPermissions()`, `updateOngoingNotification()` 전체를 `initInBackground()`로 묶어 `runApp()` 이후 비동기 실행
  - `_initialized` 플래그 추가: 초기화 완료 전에 `updateOngoingNotification()` / `scheduleReminder()` 가 호출되면 무시
- **규칙**: `runApp()` 앞에는 UI 렌더링에 반드시 필요한 초기화(Hive 등)만 둔다. 알림·권한·외부 플러그인 초기화는 `runApp()` 이후 비동기로 실행한다

---

## 작성 규칙
새 버그를 수정할 때마다 아래 형식으로 추가한다.

```
### [BUG-N] 제목
- **증상**:
- **원인**:
- **수정**:
- **규칙**: (재발 방지를 위해 지켜야 할 것)
```
