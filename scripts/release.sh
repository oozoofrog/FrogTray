#!/usr/bin/env bash

set -euo pipefail

# ─── FrogTray Release Script ──────────────────────────────────
#
# 전체 릴리스 파이프라인을 한 번에 실행합니다:
#   버전 범프 → 빌드 → DMG → 커밋/태그/푸시 → GitHub 릴리스 → Homebrew Cask 업데이트
#
# 사용법:
#   ./scripts/release.sh [옵션] [버전]
#
# 예시:
#   ./scripts/release.sh              # 패치 버전 자동 증가 (1.2 → 1.3)
#   ./scripts/release.sh 2.0          # 지정 버전으로 릴리스
#   ./scripts/release.sh --dry-run    # 실제 실행 없이 미리보기
#   ./scripts/release.sh --skip-brew  # Homebrew 업데이트 건너뛰기
# ───────────────────────────────────────────────────────────────

APP_NAME="FrogTray"
SCHEME="FrogTray"
PROJECT_DIR="FrogTray"
GITHUB_REPO="oozoofrog/FrogTray"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
PBXPROJ="${REPO_ROOT}/${PROJECT_DIR}/FrogTray.xcodeproj/project.pbxproj"
BUILD_DIR="${REPO_ROOT}/.build/release"

# Homebrew tap 경로 (환경변수로 덮어쓰기 가능)
HOMEBREW_TAP="${HOMEBREW_TAP_PATH:-${REPO_ROOT}/../homebrew-swiftnest}"

DRY_RUN=0
SKIP_BREW=0
NEW_VERSION=""

# ─── 인자 파싱 ────────────────────────────────────────────────

usage() {
  cat <<EOF
사용법: ./scripts/release.sh [옵션] [버전]

FrogTray 릴리스 전체 파이프라인:
  1. 버전 범프 (MARKETING_VERSION + CURRENT_PROJECT_VERSION)
  2. Release 빌드 + DMG 생성
  3. Git 커밋 + 태그 + 푸시
  4. GitHub Release 생성 (DMG 첨부)
  5. Homebrew Cask 업데이트 (커밋 + 푸시)

옵션:
  --dry-run       실제 실행 없이 단계별 미리보기
  --skip-brew     Homebrew Cask 업데이트 건너뛰기
  -h, --help      도움말

인자:
  [버전]          릴리스 버전 (예: 1.3, 2.0)
                  생략 시 현재 마이너 버전 +0.1 자동 증가

환경변수:
  HOMEBREW_TAP_PATH   Homebrew tap 로컬 경로 (기본: ../homebrew-swiftnest)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)   DRY_RUN=1; shift ;;
    --skip-brew) SKIP_BREW=1; shift ;;
    -h|--help)   usage; exit 0 ;;
    -*)          echo "오류: 알 수 없는 옵션: $1" >&2; usage >&2; exit 1 ;;
    *)           NEW_VERSION="$1"; shift ;;
  esac
done

# ─── 유틸리티 ─────────────────────────────────────────────────

step() { echo ""; echo "==> $1"; }
info() { echo "    $1"; }
err()  { echo "오류: $1" >&2; exit 1; }

run() {
  if [[ ${DRY_RUN} -eq 1 ]]; then
    info "[dry-run] $*"
  else
    "$@"
  fi
}

# ─── 사전 검증 ────────────────────────────────────────────────

step "[0/6] 사전 검증"

command -v gh >/dev/null 2>&1 || err "gh (GitHub CLI)가 설치되어 있지 않습니다."
command -v xcodebuild >/dev/null 2>&1 || err "xcodebuild를 찾을 수 없습니다."
[[ -f "${PBXPROJ}" ]] || err "프로젝트 파일을 찾을 수 없습니다: ${PBXPROJ}"

# 작업 디렉토리가 깨끗한지 확인 (버전 범프 커밋을 깔끔하게 만들기 위해)
if [[ ${DRY_RUN} -eq 0 ]]; then
  DIRTY=$(cd "${REPO_ROOT}" && git status --porcelain 2>/dev/null | grep -v '^\?\?' || true)
  if [[ -n "${DIRTY}" ]]; then
    err "커밋되지 않은 변경사항이 있습니다. 먼저 커밋하거나 stash하세요.\n${DIRTY}"
  fi
fi

# 현재 버전 읽기
CURRENT_VERSION=$(grep 'MARKETING_VERSION' "${PBXPROJ}" | head -1 | sed 's/.*= *//;s/ *;.*//')
CURRENT_BUILD=$(grep 'CURRENT_PROJECT_VERSION' "${PBXPROJ}" | head -1 | sed 's/.*= *//;s/ *;.*//')

info "현재 버전: ${CURRENT_VERSION} (build ${CURRENT_BUILD})"

# 새 버전 결정
if [[ -z "${NEW_VERSION}" ]]; then
  # 마이너 버전 자동 증가: 1.2 → 1.3
  MAJOR=$(echo "${CURRENT_VERSION}" | cut -d. -f1)
  MINOR=$(echo "${CURRENT_VERSION}" | cut -d. -f2)
  NEW_VERSION="${MAJOR}.$((MINOR + 1))"
fi

NEW_BUILD=$((CURRENT_BUILD + 1))

info "새 버전:   ${NEW_VERSION} (build ${NEW_BUILD})"

RELEASE_TAG="v${NEW_VERSION}"
DMG_FILENAME="${APP_NAME}-${NEW_VERSION}.dmg"
DMG_PATH="${REPO_ROOT}/${DMG_FILENAME}"

# 태그 중복 확인
if cd "${REPO_ROOT}" && git tag -l "${RELEASE_TAG}" | grep -q "${RELEASE_TAG}"; then
  err "태그 ${RELEASE_TAG}가 이미 존재합니다."
fi

if [[ ${DRY_RUN} -eq 1 ]]; then
  info ""
  info "── 실행 계획 ──"
  info "  버전: ${CURRENT_VERSION} → ${NEW_VERSION}"
  info "  빌드: ${CURRENT_BUILD} → ${NEW_BUILD}"
  info "  태그: ${RELEASE_TAG}"
  info "  DMG:  ${DMG_FILENAME}"
  info "  Homebrew: $(if [[ ${SKIP_BREW} -eq 1 ]]; then echo '건너뛰기'; else echo '업데이트'; fi)"
  info ""
fi

# ─── 1. 버전 범프 ────────────────────────────────────────────

step "[1/6] 버전 범프: ${CURRENT_VERSION} → ${NEW_VERSION} (build ${NEW_BUILD})"

if [[ ${DRY_RUN} -eq 0 ]]; then
  sed -i '' "s/MARKETING_VERSION = ${CURRENT_VERSION}/MARKETING_VERSION = ${NEW_VERSION}/g" "${PBXPROJ}"
  sed -i '' "s/CURRENT_PROJECT_VERSION = ${CURRENT_BUILD}/CURRENT_PROJECT_VERSION = ${NEW_BUILD}/g" "${PBXPROJ}"
  info "pbxproj 업데이트 완료"
else
  info "[dry-run] MARKETING_VERSION ${CURRENT_VERSION} → ${NEW_VERSION}"
  info "[dry-run] CURRENT_PROJECT_VERSION ${CURRENT_BUILD} → ${NEW_BUILD}"
fi

# ─── 2. 빌드 + DMG 생성 ──────────────────────────────────────

step "[2/6] Release 빌드"

DERIVED_DATA="${REPO_ROOT}/.build/xcode"
BUILT_APP="${DERIVED_DATA}/Build/Products/Release/${APP_NAME}.app"

if [[ ${DRY_RUN} -eq 0 ]]; then
  xcodebuild \
    -project "${REPO_ROOT}/${PROJECT_DIR}/FrogTray.xcodeproj" \
    -scheme "${SCHEME}" \
    -configuration Release \
    -derivedDataPath "${DERIVED_DATA}" \
    -destination 'platform=macOS' \
    clean build 2>&1 | tail -5

  [[ -d "${BUILT_APP}" ]] || err "빌드 실패: ${BUILT_APP}를 찾을 수 없습니다."
  info "빌드 성공: ${BUILT_APP}"
fi

step "[3/6] DMG 생성: ${DMG_FILENAME}"

if [[ ${DRY_RUN} -eq 0 ]]; then
  DMG_STAGING="${REPO_ROOT}/.build/dmg-staging"
  rm -rf "${DMG_STAGING}"
  mkdir -p "${DMG_STAGING}"

  ditto "${BUILT_APP}" "${DMG_STAGING}/${APP_NAME}.app"
  ln -s /Applications "${DMG_STAGING}/Applications"

  rm -f "${DMG_PATH}"
  TEMP_DMG="${REPO_ROOT}/.build/${APP_NAME}-temp.dmg"
  rm -f "${TEMP_DMG}"

  hdiutil create \
    -srcfolder "${DMG_STAGING}" \
    -volname "${APP_NAME}" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size 50m \
    "${TEMP_DMG}" \
    -quiet

  MOUNT_DIR=$(hdiutil attach "${TEMP_DMG}" -readwrite -noverify -noautoopen | grep "/Volumes/" | awk '{print $NF}')
  if [[ -n "${MOUNT_DIR}" ]]; then
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
    chmod -Rf go-w "${MOUNT_DIR}" 2>/dev/null || true
    sync
    hdiutil detach "${MOUNT_DIR}" -quiet
  fi

  hdiutil convert "${TEMP_DMG}" -format UDZO -imagekey zlib-level=9 -o "${DMG_PATH}" -quiet
  rm -f "${TEMP_DMG}"
  rm -rf "${REPO_ROOT}/.build"

  DMG_SIZE=$(du -sh "${DMG_PATH}" | cut -f1)
  DMG_SHA256=$(shasum -a 256 "${DMG_PATH}" | awk '{print $1}')
  info "DMG 생성 완료: ${DMG_PATH} (${DMG_SIZE})"
  info "SHA256: ${DMG_SHA256}"
else
  DMG_SHA256="<dry-run-sha256>"
  info "[dry-run] DMG 생성 → ${DMG_PATH}"
fi

# ─── 4. Git 커밋 + 태그 + 푸시 ────────────────────────────────

step "[4/6] Git 커밋, 태그, 푸시"

if [[ ${DRY_RUN} -eq 0 ]]; then
  cd "${REPO_ROOT}"
  git add "${PBXPROJ}"
  git commit -m "Bump version to ${NEW_VERSION} (build ${NEW_BUILD})"
  git tag -a "${RELEASE_TAG}" -m "Release ${RELEASE_TAG}"
  git push origin main
  git push origin "${RELEASE_TAG}"
  info "커밋 + 태그 ${RELEASE_TAG} 푸시 완료"
else
  info "[dry-run] git commit 'Bump version to ${NEW_VERSION} (build ${NEW_BUILD})'"
  info "[dry-run] git tag ${RELEASE_TAG}"
  info "[dry-run] git push origin main + ${RELEASE_TAG}"
fi

# ─── 5. GitHub Release ───────────────────────────────────────

step "[5/6] GitHub Release 생성"

RELEASE_NOTES=$(cd "${REPO_ROOT}" && git log --pretty=format:"- %s" "v${CURRENT_VERSION}..HEAD" 2>/dev/null | grep -v "Bump version" || echo "- 업데이트")

if [[ ${DRY_RUN} -eq 0 ]]; then
  gh release create "${RELEASE_TAG}" \
    "${DMG_PATH}" \
    --repo "${GITHUB_REPO}" \
    --title "${APP_NAME} ${RELEASE_TAG}" \
    --notes "${RELEASE_NOTES}"

  info "릴리스 생성 완료: https://github.com/${GITHUB_REPO}/releases/tag/${RELEASE_TAG}"

  # DMG 정리
  rm -f "${DMG_PATH}"
  info "로컬 DMG 삭제"
else
  info "[dry-run] gh release create ${RELEASE_TAG} ${DMG_FILENAME}"
  info "[dry-run] 릴리스 노트:"
  echo "${RELEASE_NOTES}" | while read -r line; do info "  ${line}"; done
fi

# ─── 6. Homebrew Cask 업데이트 ────────────────────────────────

if [[ ${SKIP_BREW} -eq 1 ]]; then
  step "[6/6] Homebrew Cask 업데이트 (건너뛰기)"
  info "--skip-brew 옵션으로 건너뜀"
else
  step "[6/6] Homebrew Cask 업데이트"

  if [[ ! -d "${HOMEBREW_TAP}" ]]; then
    err "Homebrew tap을 찾을 수 없습니다: ${HOMEBREW_TAP}\n  HOMEBREW_TAP_PATH 환경변수를 설정하세요."
  fi

  CASKS_DIR="${HOMEBREW_TAP}/Casks"
  CASK_FILE="${CASKS_DIR}/frogtray.rb"

  if [[ ${DRY_RUN} -eq 0 ]]; then
    mkdir -p "${CASKS_DIR}"

    cat > "${CASK_FILE}" <<CASK
cask "frogtray" do
  version "${NEW_VERSION}"
  sha256 "${DMG_SHA256}"

  url "https://github.com/${GITHUB_REPO}/releases/download/v#{version}/FrogTray-#{version}.dmg"
  name "FrogTray"
  desc "macOS menu bar system monitor"
  homepage "https://github.com/${GITHUB_REPO}"

  app "FrogTray.app"

  zap trash: [
    "~/Library/Preferences/com.oozoofrog.macos.FrogTray.plist",
  ]
end
CASK

    cd "${HOMEBREW_TAP}"
    git add "${CASK_FILE}"
    git commit -m "Update FrogTray cask to ${NEW_VERSION}"
    git push origin main

    info "Cask 업데이트 완료: ${CASK_FILE}"
    info "설치: brew install --cask oozoofrog/swiftnest/frogtray"
  else
    info "[dry-run] Cask 파일 생성/업데이트 → ${CASK_FILE}"
    info "[dry-run] git commit + push (homebrew-swiftnest)"
  fi
fi

# ─── 완료 ─────────────────────────────────────────────────────

echo ""
echo "============================================"
if [[ ${DRY_RUN} -eq 1 ]]; then
  echo "  [DRY RUN] 릴리스 미리보기 완료"
else
  echo "  ${APP_NAME} ${RELEASE_TAG} 릴리스 완료!"
  echo ""
  echo "  설치 방법:"
  echo "    brew install --cask oozoofrog/swiftnest/frogtray"
  echo "  업그레이드:"
  echo "    brew upgrade --cask frogtray"
fi
echo "============================================"
