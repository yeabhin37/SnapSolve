from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from passlib.context import CryptContext
from database import get_db
import models, schemas, crud  

router = APIRouter(tags=["Auth"])
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# ------ 회원가입 ------
@router.post("/register", status_code=201)
def register_user(request: schemas.UserCreate, db: Session = Depends(get_db)):
    # 이미 존재하는 사용자인지 확인
    if crud.get_user_by_name(db, request.username):
        raise HTTPException(status_code=400, detail="이미 존재하는 사용자입니다.")
    
    # 비밀번호 해싱 후 저장
    hashed_password = pwd_context.hash(request.password)
    new_user = models.User(username=request.username, password_hash=hashed_password)
    db.add(new_user)
    db.commit()
    return {"message": "회원가입 성공"}

# ------ 로그인 ------
@router.post("/login")
def login_user(request: schemas.UserLogin, db: Session = Depends(get_db)):
    user = crud.get_user_by_name(db, request.username)
    # 사용자 존재 여부 및 비밀번호 일치 여부 확인
    if not user or not pwd_context.verify(request.password, user.password_hash):
        raise HTTPException(status_code=401, detail="로그인 실패")
    return {"message": "로그인 성공", "username": user.username}
