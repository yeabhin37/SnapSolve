from sqlalchemy import Column, Integer, String, Text, ForeignKey, DateTime, JSON
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base
import uuid

def generate_uuid():
    return str(uuid.uuid4())

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    username = Column(String(50), unique=True, index=True, nullable=False)
    password_hash = Column(String, nullable=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    folders = relationship("Folder", back_populates="owner")

class Folder(Base):
    __tablename__ = "folders"

    id = Column(Integer, primary_key=True, index=True)
    name = Column(String, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))

    owner = relationship("User", back_populates="folders")
    problems = relationship("Problem", back_populates="folder", cascade="all, delete-orphan")

class Problem(Base):
    __tablename__ = "problems"

    id = Column(String, primary_key=True, default=generate_uuid)
    problem_text = Column(Text, nullable=False)             # 문제 텍스트 
    choices = Column(JSON, default=[])                      # 문제 선지 목록 (ex. 1,2,3,...)
    correct_answer = Column(String, nullable=False)         # 정답 
    folder_id = Column(Integer, ForeignKey("folders.id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    folder = relationship("Folder", back_populates="problems")
