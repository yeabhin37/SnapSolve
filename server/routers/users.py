from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.orm import Session
from database import get_db
import models, schemas, crud

router = APIRouter(tags=["Users & Stats"])

# ------ 학습 통계 업데이트 (PUT) ------
@router.put("/user/stats")
def update_user_stats(request: schemas.UserStatsUpdate, db: Session = Depends(get_db)):
    user = crud.get_user_by_name(db, request.username)
    if not user: raise HTTPException(status_code=404, detail="사용자 없음")
    
    # 기존 통계에 누적 합산
    user.total_solved += request.solved_count
    user.total_correct += request.correct_count
    
    db.commit()
    return {"message": "통계 업데이트 완료"}

# ------ 시험 점수 기록 생성 (POST) ------
@router.post("/history", status_code=201)
def create_history(request: schemas.HistoryCreate, db: Session = Depends(get_db)):
    user = crud.get_user_by_name(db, request.username)
    if not user: raise HTTPException(status_code=404)
    
    new_history = models.ExamHistory(user_id=user.id, score=request.score)
    db.add(new_history)
    db.commit()
    return {"message": "기록됨"}

# ------ 시험 점수 이력 조회 (GET) ------
@router.get("/history")
def get_histories(username: str = Query(...), db: Session = Depends(get_db)):
    user = crud.get_user_by_name(db, username)
    if not user:
        raise HTTPException(status_code=404, detail="사용자 없음")
    
    # 날짜순 정렬 후 최근 10개만
    histories = db.query(models.ExamHistory)\
        .filter(models.ExamHistory.user_id == user.id)\
        .order_by(models.ExamHistory.solved_date.asc())\
        .limit(10).all()
        
    return {
        "data": [
            {
                "date": h.solved_date.strftime("%m/%d"), # "10/25" 형식
                "score": h.score
            } for h in histories
        ]
    }