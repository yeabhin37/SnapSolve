from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base
import os
from dotenv import load_dotenv

# .env 파일에서 환경 변수 로드 (DB 접속 정보 등)
load_dotenv()

DB_HOST = os.getenv("DB_HOST")
DB_PORT = os.getenv("DB_PORT")
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
DB_NAME = os.getenv("DB_NAME")

# PostgreSQL 연결 문자열 생성
DATABASE_URL = f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"

# DB 엔진 생성
engine = create_engine(DATABASE_URL)

# 세션 팩토리 생성 (DB 작업 시마다 세션을 생성)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

# 모델 클래스들이 상속받을 Base 클래스
Base = declarative_base()

# Dependency: API 요청 시 DB 세션을 생성하고, 완료되면 닫아주는 제너레이터
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
