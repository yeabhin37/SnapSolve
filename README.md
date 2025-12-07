# 📘 SnapSolve – 찍고풀고  
나만의 맞춤형 디지털 학습지 & CBT 문제은행

스마트폰으로 **문제를 찍으면 자동으로 디지털화**하여  
학습자가 원하는 문제은행을 만들고, CBT 형태로 반복 학습할 수 있는 서비스입니다.


## 📌 1. 프로젝트 소개

기존 종이 문제집은  
- 한 번 풀면 흔적이 남아 반복 학습이 어렵고  
- 오답노트를 직접 작성해야 하는 번거로움이 있으며  
- 이동 중 학습하기도 어렵습니다.

**SnapSolve(찍고풀고)**는 이를 해결하기 위해  
문제를 촬영 → OCR 분석 → 자동 CBT 변환 → 오답노트 및 학습 통계 관리  
까지 제공하는 **All-in-One 학습 플랫폼**입니다.


## 🚀 2. 주요 기능

### 📸 OCR 기반 문제 스캔
- 카메라로 문제 촬영 또는 갤러리에서 이미지 선택 
- Naver Clova OCR 사용하여 텍스트 자동 추출  
- 문제 + 선지 자동 분리

### 📚 문제은행 (폴더) 관리
- 사용자별 폴더 생성/수정/삭제  
- 폴더별 문제 관리  
- 문제 텍스트, 선지, 정답, 메모 저장 가능

### 📝 CBT 학습 모드
- 객관식/주관식 모두 지원  
- 실시간 정답 체크  
- 학습 진행도(Progress Bar) 제공  
- 오답노트 자동 반영

### ⭐ 오답노트 시스템
- 틀린 문제 자동 분류  
- 맞힌 문제는 오답노트에서 제거 가능  
- 누적 오답 수 확인 기능

### 📊 학습 통계
- 정답률  
- 최근 10회 시험 점수 변화 그래프 


## 🛠 3. 기술 스택

### Client (Flutter)
- Dart / Flutter  
- Provider (상태관리)  
- HTTP 패키지  
- fl_chart  

### Server (FastAPI)
- FastAPI  
- SQLAlchemy  
- PostgreSQL  
- Naver Clova OCR API  
- Pydantic  
- requests


## 🗂 4. 프로젝트 구조

### 📱 Client 구조

```
client
└── lib
    ├── models
    │   ├── folder_model.dart
    │   └── problem_model.dart
    ├── services
    │   └── api_service.dart
    ├── viewmodels  # Provider 상태 관리자
    │   ├── folder_view_model.dart
    │   ├── ocr_view_model.dart
    │   ├── solve_view_model.dart
    │   └── user_view_model.dart
    ├── views
    │   ├── home_screen.dart
    │   ├── home_tab.dart
    │   ├── main_nav_screen.dart
    │   ├── ocr_preview_screen.dart
    │   ├── solve_screen.dart
    │   ├── splash_screen.dart
    │   ├── statistics_screen.dart
    │   └── workbook_tab.dart
    ├── widgets  # 공용 위젯
    │   ├── custom_buttons.dart
    │   └── problem_card.dart
    ├── constants.dart
    └── main.dart
```

### 🖥 Server 구조

```
server
├── routers
│   ├── __init__.py
│   ├── auth.py
│   ├── folders.py
│   ├── problems.py
│   └── users.py
├── utils
│   ├── __init__.py
│   └── ocr.py
├── .env
├── crud.py
├── database.py
├── main.py
├── models.py
├── requirements.txt
├── schemas.py
└── shared_data.py
```

## 🔗 5. REST API 명세 (요약)

### 🔐 사용자 인증
| Method | Endpoint | 설명 |
|-------|----------|------|
| POST | `/register` | 회원가입 |
| POST | `/login` | 로그인 |

### 📁 폴더 관리
| Method | Endpoint | 설명 |
|-------|----------|------|
| GET | `/folders?username=` | 폴더 목록 조회 |
| POST | `/folders` | 폴더 생성 |
| PUT | `/folders/{folder_id}` | 폴더 수정 |
| DELETE | `/folders/{folder_id}` | 폴더 삭제 |

### 📄 문제 관리
| Method | Endpoint | 설명 |
|-------|----------|------|
| POST | `/ocr` | OCR 분석 요청 |
| POST | `/problems` | 문제 저장 |
| GET | `/problems?folder_id` | 폴더별 문제 조회 |
| PUT | `/problems/{id}` | 문제 수정 |
| DELETE | `/problems/{id}` | 문제 삭제 |

### ⭐ 오답노트
| Method | Endpoint | 설명 |
|-------|----------|------|
| GET | `/wrong-notes?username` | 전체 오답 조회 |
| PATCH | `/problems/wrong-note` | 다중 오답 상태 업데이트 |

### 📊 통계/히스토리
| Method | Endpoint | 설명 |
|-------|----------|------|
| PUT | `/user/stats` | 통계 업데이트 |
| POST | `/history` | 점수 기록 저장 |
| GET | `/history?username` | 최근 점수 기록 조회 |

---

## 🧪 6. 로컬 실행 방법

### 🔧 환경 변수 설정 필요 
```
DB_HOST=
DB_PORT=
DB_USER=
DB_PASSWORD=
DB_NAME=
CLOVA_OCR_URL=
CLOVA_OCR_SECRET=
```

### 🔧 Server 실행
```
cd server
.\.venv\Scripts\Activate.ps1
uvicorn main:app --reload
```

### 🔧 client 실행 
```
cd client 
flutter run 
```
