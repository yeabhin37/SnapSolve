from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy.orm import Session
from database import get_db
import models, schemas, crud

router = APIRouter(tags=["Folders"])

# ------ 폴더 목록 조회 (GET) ------
@router.get("/folders")
def get_folders(username: str = Query(...), db: Session = Depends(get_db)):
    user = crud.get_user_by_name(db, username)
    if not user: raise HTTPException(status_code=404, detail="사용자 없음")
    
    # 전체 오답노트(별표) 개수 계산
    total_wrong_count = 0
    for f in user.folders:
        for p in f.problems:
            if p.is_wrong_note:
                total_wrong_count += 1
    
    # 전체 정답률 계산 (0으로 나누기 방지)
    accuracy = 0
    if user.total_solved > 0:
        accuracy = int((user.total_correct / user.total_solved) * 100)

    # 폴더 리스트와 통계 정보를 함께 반환
    return {
        "folders": [
            {
                "id": f.id,
                "name": f.name, 
                "color": f.color, 
                "problem_count": len(f.problems)
            } for f in user.folders
        ],
        "wrong_note_count": total_wrong_count,
        "accuracy": accuracy
    }

# ------ 폴더 생성 (POST) ------
@router.post("/folders", status_code=201)
def create_folder(request: schemas.FolderCreate, db: Session = Depends(get_db)):
    user = crud.get_user_by_name(db, request.username)
    if not user: raise HTTPException(status_code=404, detail="사용자 없음")

    new_folder = models.Folder(name=request.folder_name, user_id=user.id, color=request.color)
    db.add(new_folder)
    db.commit()
    return {"message": "폴더 생성 완료", "id": new_folder.id}

# ------ 폴더 수정 (PUT) ------
@router.put("/folders/{folder_id}")
def update_folder(folder_id: int, request: schemas.FolderUpdate, db: Session = Depends(get_db)):
    folder = crud.get_folder_by_id(db, folder_id)
    if not folder: raise HTTPException(status_code=404, detail="폴더 없음")
    
    folder.name = request.new_name
    folder.color = request.new_color
    db.commit()
    return {"message": "수정 완료"}

# ------ 폴더 삭제 (DELETE) ------
@router.delete("/folders/{folder_id}", status_code=204)
def delete_folder(folder_id: int, username: str = Query(...), db: Session = Depends(get_db)):
    folder = crud.get_folder_by_id(db, folder_id)
    if not folder: 
        raise HTTPException(status_code=404, detail="폴더 없음")
    
    # 소유권 확인 
    user = crud.get_user_by_name(db, username)
    if not user or folder.user_id != user.id:
        raise HTTPException(status_code=403, detail="권한 없음")

    db.delete(folder)
    db.commit()
    return Response(status_code=204)
