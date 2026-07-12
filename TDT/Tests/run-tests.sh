#!/bin/zsh
# TodoStore 스탠드얼론 테스트 실행
# (테스트 파일은 top-level 코드라 main.swift로 복사해 컴파일한다)
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
TMP=$(mktemp -d)
cp "$DIR/TodoStoreTests.swift" "$TMP/main.swift"
swiftc -o "$TMP/todostore_tests" \
  "$DIR/../TDT/Data/TodoData.swift" \
  "$DIR/../TDT/Data/TodoStore.swift" \
  "$TMP/main.swift"
"$TMP/todostore_tests"
