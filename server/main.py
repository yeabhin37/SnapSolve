from fastapi import FastAPI
from database import engine
import models
from routers import auth, folders, problems, users 

# [주의] 데이터베이스 초기화(drop_all) 코드가 포함되어 있으니 필요시 주석 해제하기 
models.Base.metadata.drop_all(bind=engine)   
models.Base.metadata.create_all(bind=engine)

app = FastAPI()

# 라우터 등록 (기능별 API 분리)
app.include_router(auth.router)         # 회원가입/로그인
app.include_router(folders.router)      # 폴더 관리 
app.include_router(problems.router)     # 문제 및 OCR 관련 
app.include_router(users.router)        # 사용자 통계 및 히스토리 관리 

@app.get("/")
def root():
    return {"message": "SnapSolve API Server Running"}