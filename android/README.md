# Flick Android

iOS 3.0 스펙(`docs/android-handoff.md`)과 3.0.1 변경분(`docs/3.0.1-plan.md`) 기반 안드로이드 버전. 서버 없음, 100% 로컬.

## 빌드·실행

```bash
cd android
./gradlew assembleDebug          # APK: app/build/outputs/apk/debug/
./gradlew :app:testDebugUnitTest # 유닛 테스트 37개 (TodoStore 23 + 위젯 규칙 6 + 링크 감지 8)
```

요구사항: JDK 17, Android SDK 36. `local.properties`에 `sdk.dir` 지정.

## 출시 빌드

업로드 키를 한 번 만들고(비밀번호를 직접 입력), 저장소 밖에 보관한다. 잃어버리면 Play Console에서 재설정 요청이 필요하다.

```bash
keytool -genkeypair -v -keystore ~/flick-upload.jks -alias flick-upload -keyalg RSA -keysize 2048 -validity 10000
```

`keystore.properties.example`을 `keystore.properties`로 복사해 값을 채운 뒤 AAB를 만든다.

```bash
./gradlew bundleRelease # app/build/outputs/bundle/release/app-release.aab
```

`keystore.properties`와 키 파일은 커밋하지 않는다. 파일이 없으면 서명되지 않은 AAB가 나오며 Play Console에 올릴 수 없다.
출시할 때마다 `versionCode`를 올린다. 스토어용 512px 아이콘은 `store/icon-512.png`에 있다.

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
