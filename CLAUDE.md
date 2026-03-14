# FrogTray

macOS 메뉴바 시스템 모니터 앱. "개구리 연못" 테마.

## 뷰 계층 명명 (에이전트 소통용)

```
🐸 개구리네 (FrogTrayApp)
│
├── 이마 (FrogMenuBarLabel) — 메뉴바에 항상 보이는 부분
│   ├── 눈깔 (FrogStatusIcon) — 개구리 아이콘
│   └── 이마글씨 — C/M/D 수치 텍스트
│
└── 배 (ContentView) — 클릭 시 열리는 트레이 윈도우
    │
    ├── 연못 (mainView) — 대시보드 메인 화면
    │   ├── 수면 (summaryCard) — 요약 카드 (개구리 + 3개 게이지)
    │   ├── 물결 (MetricCard) × 3 — CPU/메모리/디스크 메트릭 카드
    │   ├── 둑 (settingsCard) — 설정 카드 (로그인 시 실행 등)
    │   └── 발판 (actionRow) — 하단 액션 바 (새로고침/종료)
    │
    └── 깊은곳 (MetricDetailView) — 메트릭 상세 화면
        ├── CPU 깊은곳
        ├── 메모리 깊은곳
        └── 디스크 깊은곳
```

### 공통 부품

| 한글 명칭 | 코드 대응 | 설명 |
|-----------|----------|------|
| 잎 | TrayCard | 글라스모픽 카드 컨테이너 |
| 방울 | miniGauge | 원형 게이지 |
| 수위 | Capsule progress bar | 캡슐형 프로그레스 바 |
| 물목록 | processListCard | 프로세스 리스트 카드 |
| 이끼표 | StatusBadge / SectionHeader | 상태 배지, 섹션 헤더 |
