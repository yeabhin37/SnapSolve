import os
import uuid
import json
import time
import base64
import requests
from fastapi import APIRouter, Depends, HTTPException, Query, Response 
from sqlalchemy.orm import Session
from database import get_db
import models, schemas, crud  
from shared_data import temp_ocr_results
from utils.ocr import parse_clova_ocr_response 

router = APIRouter(tags=["Problems"])

# ------ OCR 처리 (CLOVA OCR API 연동) ------
@router.post("/ocr") 
def ocr_problem(request: schemas.OcrRequest): 
    api_url = os.getenv("CLOVA_OCR_URL")
    secret_key = os.getenv("CLOVA_OCR_SECRET")
    if not api_url or not secret_key:
        raise HTTPException(status_code=500, detail="OCR API 환경 변수가 설정되지 않았습니다.")
    
    # Base64 이미지 디코딩
    try:
        header, encoded = request.image_data.split(",", 1)
        image_bytes = base64.b64decode(encoded)
        image_format = header.split(';')[0].split('/')[-1]
    except:
        raise HTTPException(status_code=400, detail="잘못된 이미지 데이터 형식입니다.")
    
    # Clova OCR API 요청 구성
    request_json = {'images': [{'format': image_format, 'name': 'temp_image'}],'requestId': str(uuid.uuid4()),'version': 'V2','timestamp': int(round(time.time() * 1000))}
    payload = {'message': json.dumps(request_json)}
    files = [('file', image_bytes)]
    headers = {'X-OCR-SECRET': secret_key}

    # API 요청 전송
    response = requests.post(api_url, headers=headers, data=payload, files=files)
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=f"OCR API 오류: {response.text}")
    
    # 결과 파싱 (utils/ocr.py 사용)
    ocr_response_json = response.json()
    parsed_data = parse_clova_ocr_response(ocr_response_json)
    if not parsed_data:
        raise HTTPException(status_code=400, detail="이미지에서 텍스트를 추출하지 못했거나, 문제 형식을 인식할 수 없습니다.")
    
    # 임시 저장소(temp_ocr_results)에 결과 저장하고 temp_id 반환
    problem_data = parsed_data[0]
    temp_id = str(uuid.uuid4())
    temp_ocr_results[temp_id] = problem_data
    return {"temp_id": temp_id, "preview": problem_data}

# ------ 문제 최종 저장 ------
@router.post("/problems", status_code=201)
def save_problem(request: schemas.SaveProblemRequest, db: Session = Depends(get_db)):
    # 임시 ID로 OCR 데이터 조회 (유효성 검사)
    if request.temp_id not in temp_ocr_results:
        raise HTTPException(status_code=404, detail="임시 데이터 만료")
    
    ocr_data = temp_ocr_results.pop(request.temp_id)
    folder = crud.get_folder_by_id(db, request.folder_id)
    if not folder: raise HTTPException(status_code=404, detail="폴더 없음")

    # 클라이언트에서 수정한 값이 있으면 우선 사용, 없으면 OCR 원본 사용
    final_text = request.problem_text if request.problem_text else ocr_data['problem']
    final_choices = request.choices if request.choices else ocr_data['choices']

    new_prob = models.Problem(
        problem_text=final_text,
        choices=final_choices,
        correct_answer=request.correct_answer,
        folder_id=folder.id,
        memo=request.memo
    )
    db.add(new_prob)
    db.commit()
    return {"message": "저장 완료", "id": new_prob.id}

# ------ 폴더 내 문제 목록 조회 (GET) ------
@router.get("/problems")
def get_problems(folder_id: int = Query(...), db: Session = Depends(get_db)):
    folder = crud.get_folder_by_id(db, folder_id)
    if not folder: raise HTTPException(status_code=404, detail="폴더 없음")
    
    problems = {}
    for p in folder.problems:
        problems[p.id] = {
            "problem": p.problem_text,
            "choices": p.choices,
            "answer": p.correct_answer,
            "is_wrong_note": p.is_wrong_note,
            "memo": p.memo
        }
    return {"problems": problems}

# ------ 문제 수정 (PUT) ------
@router.put("/problems/{problem_id}")
def update_problem(problem_id: str, request: schemas.UpdateProblemRequest, db: Session = Depends(get_db)):
    problem = db.query(models.Problem).filter(models.Problem.id == problem_id).first()
    if not problem: raise HTTPException(status_code=404, detail="문제 없음")
    
    if request.problem_text: problem.problem_text = request.problem_text
    if request.correct_answer: problem.correct_answer = request.correct_answer
    db.commit()
    return {"message": "수정 완료"}

# ------ 문제 삭제 (DELETE) ------
@router.delete("/problems/{problem_id}", status_code=204)
def delete_problem(problem_id: str, db: Session = Depends(get_db)):
    problem = db.query(models.Problem).filter(models.Problem.id == problem_id).first()
    if not problem: 
        raise HTTPException(status_code=404, detail="문제 없음")
    
    db.delete(problem)
    db.commit()
    return Response(status_code=204)

# ------ 문제 정답 채점 (POST) ------
@router.post("/problems/{problem_id}/submissions") 
def check_answer(problem_id: str, request: schemas.SolveRequest, db: Session = Depends(get_db)):
    problem = db.query(models.Problem).filter(models.Problem.id == problem_id).first()
    if not problem: 
        raise HTTPException(status_code=404, detail="문제 없음")
    
    is_correct = (problem.correct_answer == request.user_answer)
    # 채점 결과 리턴 (200 OK 사용 - 결과를 리턴해야 하므로)
    return {"result": "정답" if is_correct else "오답", "is_correct": is_correct}

# ------ 오답노트 조회 (GET) ------
@router.get("/wrong-notes")
def get_wrong_notes(username: str = Query(...), db: Session = Depends(get_db)):
    user = crud.get_user_by_name(db, username)
    if not user: raise HTTPException(status_code=404, detail="사용자 없음")
    
    # 모든 폴더를 순회하며 is_wrong_note=True인 문제 수집
    wrong_problems = {}
    for folder in user.folders:
        for p in folder.problems:
            if p.is_wrong_note:
                wrong_problems[p.id] = {
                    "problem": p.problem_text,
                    "choices": p.choices,
                    "answer": p.correct_answer,
                    "is_wrong_note": True
                }
    return {"problems": wrong_problems}


# ------ 오답노트 상태 일괄 변경 (PATCH) ------
@router.patch("/problems/wrong-note")
def bulk_update_wrong_note(request: schemas.WrongNoteUpdate, db: Session = Depends(get_db)):
    db.query(models.Problem).\
        filter(models.Problem.id.in_(request.problem_ids)).\
        update({models.Problem.is_wrong_note: request.is_wrong_note}, synchronize_session=False)
    db.commit()
    return {"message": "업데이트 완료"}