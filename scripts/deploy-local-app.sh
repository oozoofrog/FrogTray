#!/usr/bin/env bash

set -euo pipefail

APP_NAME="FrogTray"
SCHEME="FrogTray"
PROJECT_PATH="FrogTray/FrogTray.xcodeproj"
CONFIGURATION="Release"
DESTINATION_DIR="${HOME}/Applications"
RUN_AFTER_DEPLOY=0

usage() {
  cat <<EOF
사용법:
  ./scripts/deploy-local-app.sh [옵션]

옵션:
  --debug           Debug 구성으로 빌드
  --release         Release 구성으로 빌드 (기본값)
  --run             배포 후 앱 실행
  --destination DIR 배포 폴더 지정 (기본값: ~/Applications)
  -h, --help        도움말 표시

예시:
  ./scripts/deploy-local-app.sh
  ./scripts/deploy-local-app.sh --debug --run
  ./scripts/deploy-local-app.sh --destination "/tmp/Apps"
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
    --run)
      RUN_AFTER_DEPLOY=1
      shift
      ;;
    --destination)
      if [[ $# -lt 2 ]]; then
        echo "오류: --destination 뒤에 경로가 필요합니다." >&2
        exit 1
      fi
      DESTINATION_DIR="$2"
      shift 2
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
DEPLOYED_APP_PATH="${DESTINATION_DIR}/${APP_NAME}.app"

echo "==> 저장소 루트: ${REPO_ROOT}"
echo "==> 빌드 구성: ${CONFIGURATION}"
echo "==> DerivedData: ${DERIVED_DATA_PATH}"
echo "==> 배포 경로: ${DEPLOYED_APP_PATH}"

mkdir -p "${DESTINATION_DIR}"

echo "==> 기존 실행 중인 ${APP_NAME} 종료 시도"
pkill -x "${APP_NAME}" 2>/dev/null || true

echo "==> xcodebuild 실행"
xcodebuild \
  -project "${REPO_ROOT}/${PROJECT_PATH}" \
  -scheme "${SCHEME}" \
  -configuration "${CONFIGURATION}" \
  -derivedDataPath "${DERIVED_DATA_PATH}" \
  -destination 'platform=macOS' \
  build

if [[ ! -d "${BUILT_APP_PATH}" ]]; then
  echo "오류: 빌드된 앱을 찾을 수 없습니다: ${BUILT_APP_PATH}" >&2
  exit 1
fi

echo "==> 기존 배포 앱 교체"
rm -rf "${DEPLOYED_APP_PATH}"
ditto "${BUILT_APP_PATH}" "${DEPLOYED_APP_PATH}"

echo "==> 배포 완료: ${DEPLOYED_APP_PATH}"

if [[ ${RUN_AFTER_DEPLOY} -eq 1 ]]; then
  echo "==> 앱 실행"
  open "${DEPLOYED_APP_PATH}"
fi

