#!/usr/bin/env bash

set -euo pipefail

APP_NAME="FrogTray"
SCHEME="FrogTray"
PROJECT_PATH="FrogTray/FrogTray.xcodeproj"
CONFIGURATION="Release"
SKIP_BUILD=0
OPEN_DMG=0

usage() {
  cat <<EOF
사용법:
  ./scripts/build-dmg.sh [옵션]

Release clean 빌드 → DMG 생성 → ~/Applications 설치 → 앱 실행을 수행합니다.
DMG에는 FrogTray.app과 /Applications 바로가기가 포함되어
드래그 앤 드롭으로도 설치할 수 있습니다.

옵션:
  --debug           Debug 구성으로 빌드
  --release         Release 구성으로 빌드 (기본값)
  --skip-build      빌드를 건너뛰고 기존 빌드 결과로 DMG 생성
  --open            DMG 생성 후 Finder에서 열기
  -h, --help        도움말 표시

예시:
  ./scripts/build-dmg.sh
  ./scripts/build-dmg.sh --debug
  ./scripts/build-dmg.sh --skip-build --open
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug)
      CONFIGURATION="Debug"
      shift
      ;;
    --release)
      CONFIGURATION="Release"
      shift
      ;;
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    --open)
      OPEN_DMG=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "오류: 알 수 없는 옵션: $1" >&2
      echo >&2
      usage >&2
      exit 1
      ;;
  esac
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
DERIVED_DATA_PATH="${REPO_ROOT}/.build/xcode"
BUILT_APP_PATH="${DERIVED_DATA_PATH}/Build/Products/${CONFIGURATION}/${APP_NAME}.app"
DMG_OUTPUT_DIR="${REPO_ROOT}"
DMG_STAGING_DIR="${REPO_ROOT}/.build/dmg-staging"

# 앱 버전 가져오기 (빌드 후 Info.plist에서 읽거나 기본값 사용)
get_app_version() {
  if [[ -d "${BUILT_APP_PATH}" ]]; then
    local version
    version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "${BUILT_APP_PATH}/Contents/Info.plist" 2>/dev/null || echo "1.0")
    local build
    build=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "${BUILT_APP_PATH}/Contents/Info.plist" 2>/dev/null || echo "1")
    echo "${version}-${build}"
  else
    echo "1.0-1"
  fi
}

echo "============================================"
echo "  ${APP_NAME} DMG 빌드 스크립트"
echo "============================================"
echo ""
echo "  빌드 구성:    ${CONFIGURATION}"
echo "  저장소 루트:  ${REPO_ROOT}"
echo "  DerivedData:  ${DERIVED_DATA_PATH}"
echo ""

# ── 1. 빌드 ──────────────────────────────────

if [[ ${SKIP_BUILD} -eq 0 ]]; then
  echo "==> [1/4] xcodebuild clean build (${CONFIGURATION})"
  xcodebuild \
    -project "${REPO_ROOT}/${PROJECT_PATH}" \
    -scheme "${SCHEME}" \
    -configuration "${CONFIGURATION}" \
    -derivedDataPath "${DERIVED_DATA_PATH}" \
    -destination 'platform=macOS' \
    clean build \
    | tail -5

  echo ""
else
  echo "==> [1/4] 빌드 건너뜀 (--skip-build)"
fi

if [[ ! -d "${BUILT_APP_PATH}" ]]; then
  echo "오류: 빌드된 앱을 찾을 수 없습니다: ${BUILT_APP_PATH}" >&2
  exit 1
fi

APP_VERSION=$(get_app_version)
DMG_FILENAME="${APP_NAME}-${APP_VERSION}.dmg"
DMG_PATH="${DMG_OUTPUT_DIR}/${DMG_FILENAME}"

echo "  앱 버전:      ${APP_VERSION}"
echo "  DMG 파일:     ${DMG_PATH}"
echo ""

# ── 2. 스테이징 디렉토리 준비 ─────────────────

echo "==> [2/4] 스테이징 디렉토리 준비"
rm -rf "${DMG_STAGING_DIR}"
mkdir -p "${DMG_STAGING_DIR}"

# 앱 복사
ditto "${BUILT_APP_PATH}" "${DMG_STAGING_DIR}/${APP_NAME}.app"

# /Applications 심볼릭 링크 (드래그 앤 드롭 설치용)
ln -s /Applications "${DMG_STAGING_DIR}/Applications"

echo "  스테이징 완료: ${DMG_STAGING_DIR}"

# ── 3. DMG 생성 ──────────────────────────────

echo "==> [3/4] DMG 생성"
mkdir -p "${DMG_OUTPUT_DIR}"

# 기존 DMG 삭제
rm -f "${DMG_PATH}"

# 임시 read-write DMG 생성
TEMP_DMG="${REPO_ROOT}/.build/${APP_NAME}-temp.dmg"
rm -f "${TEMP_DMG}"

hdiutil create \
  -srcfolder "${DMG_STAGING_DIR}" \
  -volname "${APP_NAME}" \
  -fs HFS+ \
  -fsargs "-c c=64,a=16,e=16" \
  -format UDRW \
  -size 50m \
  "${TEMP_DMG}" \
  -quiet

# DMG 마운트
MOUNT_DIR=$(hdiutil attach "${TEMP_DMG}" -readwrite -noverify -noautoopen | grep "/Volumes/" | awk '{print $NF}')

if [[ -n "${MOUNT_DIR}" ]]; then
  # Finder 창 설정 (아이콘 크기, 배경, 위치)
  echo '
    tell application "Finder"
      tell disk "'"${APP_NAME}"'"
        open
        set current view of container window to icon view
        set toolbar visible of container window to false
        set statusbar visible of container window to false
        set the bounds of container window to {400, 200, 800, 480}
        set viewOptions to the icon view options of container window
        set arrangement of viewOptions to not arranged
        set icon size of viewOptions to 80
        set position of item "'"${APP_NAME}.app"'" of container window to {120, 140}
        set position of item "Applications" of container window to {280, 140}
        close
        open
        update without registering applications
        delay 1
        close
      end tell
    end tell
  ' | osascript 2>/dev/null || true

  # 권한 설정
  chmod -Rf go-w "${MOUNT_DIR}" 2>/dev/null || true

  sync
  hdiutil detach "${MOUNT_DIR}" -quiet
fi

# 최종 압축 DMG로 변환
hdiutil convert \
  "${TEMP_DMG}" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "${DMG_PATH}" \
  -quiet

rm -f "${TEMP_DMG}"

# .build 디렉토리 정리
rm -rf "${REPO_ROOT}/.build"

DMG_SIZE=$(du -sh "${DMG_PATH}" | cut -f1)
echo "  DMG 생성 완료: ${DMG_PATH} (${DMG_SIZE})"

# ── 4. 종료 → 설치 → 실행 ─────────────────────

echo "==> [4/5] ~/Applications에 설치"

DESTINATION_DIR="${HOME}/Applications"
DEPLOYED_APP_PATH="${DESTINATION_DIR}/${APP_NAME}.app"
mkdir -p "${DESTINATION_DIR}"

echo "  기존 실행 중인 ${APP_NAME} 종료 시도"
pkill -x "${APP_NAME}" 2>/dev/null || true
sleep 1

echo "  DMG에서 ~/Applications에 설치"
DMG_MOUNT=$(hdiutil attach "${DMG_PATH}" -nobrowse -noverify -noautoopen | grep "/Volumes/" | awk '{print $NF}')
rm -rf "${DEPLOYED_APP_PATH}"
ditto "${DMG_MOUNT}/${APP_NAME}.app" "${DEPLOYED_APP_PATH}"
hdiutil detach "${DMG_MOUNT}" -quiet

echo "==> [5/5] 앱 실행"
open "${DEPLOYED_APP_PATH}"

if [[ ${OPEN_DMG} -eq 1 ]]; then
  echo "  DMG를 Finder에서 열기"
  open "${DMG_PATH}"
fi

echo ""
echo "============================================"
echo "  완료!"
echo "  DMG: ${DMG_PATH}"
echo "============================================"
