from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, JSON, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
import uuid

# 문제 ID 생성을 위한 UUID 함수
def generate_uuid():
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    # 통계용 컬럼 
    total_solved = Column(Integer, default=0)  # 전체 푼 문제 수
    total_correct = Column(Integer, default=0) # 정답 수

    # 관계 정의 (User -> Folder, User -> ExamHistory)
    folders = relationship("Folder", back_populates="owner")
    histories = relationship("ExamHistory", back_populates="owner")

class Folder(Base):
    __tablename__ = "folders"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    color = Column(String, default="0xFF1E2B58")    # 폴더 색상 코드 
    user_id = Column(Integer, ForeignKey("users.id"))

    owner = relationship("User", back_populates="folders")
    # 폴더 삭제 시 내부 문제도 함께 삭제 (cascade)
    problems = relationship("Problem", back_populates="folder", cascade="all, delete-orphan")

class Problem(Base):
    __tablename__ = "problems"

    id = Column(String, primary_key=True, default=generate_uuid)    # UUID 사용 
    problem_text = Column(Text, nullable=False)                     # 문제 지문
    choices = Column(JSON, default=[])                              # 객관식 선지 (리스트 형태 JSON)
    correct_answer = Column(String, nullable=False)                 # 정답 
    folder_id = Column(Integer, ForeignKey("folders.id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    is_wrong_note = Column(Boolean, default=False)                  # 오답노트 포함 여부 
    memo = Column(Text, nullable=True)                              # 사용자 메모 
    
    folder = relationship("Folder", back_populates="problems")

class ExamHistory(Base):
    __tablename__ = "exam_histories"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    score = Column(Integer, nullable=False) # 점수 (0~100)
    solved_date = Column(DateTime(timezone=True), server_default=func.now()) # 시험 본 날짜

    owner = relationship("User", back_populates="histories")