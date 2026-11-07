# Flick Android

iOS 3.0 스펙(`docs/android-handoff.md`)과 3.0.1 변경분(`docs/3.0.1-plan.md`) 기반 안드로이드 버전. 서버 없음, 100% 로컬.

## 빌드·실행

```bash
cd android
./gradlew assembleDebug          # APK: app/build/outputs/apk/debug/
./gradlew :app:testDebugUnitTest # 유닛 테스트 37개 (TodoStore 23 + 위젯 규칙 6 + 링크 감지 8)
```

요구사항: JDK 17, Android SDK 35. `local.properties`에 `sdk.dir` 지정.

## 구조 (단일 모듈)

```
app/src/main/java/com/qodhrkawk/flick/
├── data/       TodoData·TodoStore(순수 Kotlin, iOS 로직 포팅)·저장소·위젯 규칙·링크 감지
├── ui/         FlickAppState(상태 홀더)·TodoScreen·ArchiveScreen·SettingsScreen·테마
├── widget/     Glance 위젯 3종(홈·오늘·소형) + 갱신 동기화
└── MainActivity.kt  페이저(메인↔아카이브) + 설정 오버레이
```

- 데이터 로직은 `TodoStore`에 모여 있고 UI 의존이 없다. iOS `TodoStoreTests.swift`의
  19개 케이스가 `TodoStoreTest.kt`로 그대로 이식되어 있다.
- 제스처 구현의 함정 3가지는 `docs/android-spike-findings.md` 참고 (셀 레벨 감지기,
  onDragCancel 처리, scrollToItem 보정). 수정 전에 반드시 읽을 것.
- QA: `docs/android-qa-checklist.md`
