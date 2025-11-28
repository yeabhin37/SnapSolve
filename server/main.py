import os
import base64
import uuid
import re
import json
import time
import cv2
import numpy as np
import requests
from fastapi import FastAPI, HTTPException, Depends 
from sqlalchemy.orm import Session 
from typing import List, Dict
from database import engine, Base, get_db
import models, schemas 

models.Base.metadata.create_all(bind=engine)

app = FastAPI()

temp_ocr_results = {} # OCR 미리보기 결과를 임시 저장하는 곳

def get_user_by_name(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first() 

def get_folder_by_name(db: Session, user_id: int, folder_name: str):
    return db.query(models.Folder).filter(models.Folder.user_id == user_id, models.Folder.name == folder_name).first()

# --- Naver Clova OCR 파싱 함수 ---
def parse_clova_ocr_response(response_json: Dict) -> List[Dict]:
    """
    Naver Clova OCR 응답 JSON을 파싱하여 문제와 선지로 분리합니다.
    한 이미지에 하나의 문제가 있다고 가정합니다.
    """
    try:
        fields = response_json['images'][0]['fields']
        if not fields:
            return []

        texts = [field['inferText'] for field in fields]

        # 선지 번호(예: '①', '2')를 나타내는 텍스트 필드의 인덱스를 찾습니다.
        # 정규식: 문자열 전체가 원 문자 또는 한 자리 숫자로만 구성된 경우
        choice_marker_indices = [
            i for i, text in enumerate(texts)
            if re.fullmatch(r'[①②③④⑤]|\d', text)
        ]

        # 문제 번호(예: 11, 12)와 선지 번호를 구분하기 위해,
        # 연속적으로 나타나는 숫자 패턴의 첫 시작을 실제 선지의 시작으로 간주합니다.
        if not choice_marker_indices:
            # 선지를 찾지 못한 경우, 전체를 문제로 간주
            problem_text = " ".join(texts)
            return [{"problem": problem_text.strip(), "choices": []}]

        # 첫 번째 선지 번호가 시작되는 인덱스를 기준으로 문제와 선지를 분리합니다.
        first_choice_index_in_texts = choice_marker_indices[0]

        # 문제 텍스트 파싱 (첫 선지 번호 이전의 모든 텍스트)
        problem_text = " ".join(texts[:first_choice_index_in_texts]).strip()

        # 선지 텍스트 파싱
        choices = []
        for i in range(len(choice_marker_indices)):
            start_index = choice_marker_indices[i]
            # 다음 선지가 있으면 그 전까지, 마지막 선지이면 텍스트 끝까지를 범위로 지정
            end_index = choice_marker_indices[i + 1] if i + 1 < len(choice_marker_indices) else len(texts)
            
            choice_text = " ".join(texts[start_index:end_index]).strip()
            choices.append(choice_text)

        return [{"problem": problem_text, "choices": choices}]

    except (KeyError, IndexError) as e:
        raise HTTPException(status_code=500, detail=f"OCR 응답 파싱 실패: {e}")


# -----------------------------
#        API Endpoints 
# -----------------------------

# 사용자 등록 
@app.post("/register")
def register_user(request: schemas.UserCreate, db: Session = Depends(get_db)):
    if get_user_by_name(db, request.username):
        raise HTTPException(status_code=400, detail="이미 존재하는 사용자입니다.")
    
    # password가 오지 않아도 기본값이나 더미 값을 넣어줍니다.
    new_user = models.User(
        username=request.username, 
        password_hash=request.password # 스키마 기본값 "1234"가 들어감
    )
    db.add(new_user)
    db.commit()
    return {"message": f"'{request.username}'님 환영합니다!"}

@app.post("/create-folder")
def create_folder(request: schemas.FolderCreate, db: Session = Depends(get_db)):
    user = get_user_by_name(db, request.username)
    if not user:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    
    if get_folder_by_name(db, user.id, request.folder_name):
        raise HTTPException(status_code=400, detail="이미 존재하는 폴더입니다.")
        
    new_folder = models.Folder(name=request.folder_name, user_id=user.id)
    db.add(new_folder)
    db.commit()
    return {"message": f"'{request.folder_name}' 폴더 생성 완료"}

@app.post("/ocr") 
def ocr_problem(request: schemas.OcrRequest): 
    api_url = os.getenv("CLOVA_OCR_URL")
    secret_key = os.getenv("CLOVA_OCR_SECRET")
    if not api_url or not secret_key:
        raise HTTPException(status_code=500, detail="OCR API 환경 변수가 설정되지 않았습니다.")
    try:
        header, encoded = request.image_data.split(",", 1)
        image_bytes = base64.b64decode(encoded)
        image_format = header.split(';')[0].split('/')[-1]
    except:
        raise HTTPException(status_code=400, detail="잘못된 이미지 데이터 형식입니다.")
    request_json = {'images': [{'format': image_format, 'name': 'temp_image'}],'requestId': str(uuid.uuid4()),'version': 'V2','timestamp': int(round(time.time() * 1000))}
    payload = {'message': json.dumps(request_json)}
    files = [('file', image_bytes)]
    headers = {'X-OCR-SECRET': secret_key}
    response = requests.post(api_url, headers=headers, data=payload, files=files)
    if response.status_code != 200:
        raise HTTPException(status_code=response.status_code, detail=f"OCR API 오류: {response.text}")
    ocr_response_json = response.json()
    parsed_data = parse_clova_ocr_response(ocr_response_json)
    if not parsed_data:
        raise HTTPException(status_code=400, detail="이미지에서 텍스트를 추출하지 못했거나, 문제 형식을 인식할 수 없습니다.")
    problem_data = parsed_data[0]
    temp_id = str(uuid.uuid4())
    temp_ocr_results[temp_id] = problem_data
    return {"temp_id": temp_id, "preview": problem_data}

@app.post("/save")
def save_problem(request: schemas.SaveRequest, db: Session = Depends(get_db)):
    if request.temp_id not in temp_ocr_results:
        raise HTTPException(status_code=404, detail="만료되었거나 잘못된 임시 ID")
    
    user = get_user_by_name(db, request.username)
    if not user: raise HTTPException(status_code=404, detail="사용자 없음")
    
    folder = get_folder_by_name(db, user.id, request.folder_name)
    if not folder: raise HTTPException(status_code=404, detail="폴더 없음")
    
    ocr_data = temp_ocr_results.pop(request.temp_id)
    new_problem = models.Problem(
        problem_text=ocr_data['problem'],
        choices=ocr_data['choices'],
        correct_answer=request.correct_answer,
        folder_id=folder.id
    )
    db.add(new_problem)
    db.commit()
    db.refresh(new_problem)
    return {"message": "저장 완료", "problem_id": new_problem.id}

@app.post("/folders")
def get_folders(request: schemas.UserCreate, db: Session = Depends(get_db)):
    user = get_user_by_name(db, request.username)
    if not user: raise HTTPException(status_code=404, detail="사용자 없음")
    return {"folders": [f.name for f in user.folders]}

@app.post("/problems")
def get_problems(request: schemas.FolderCreate, db: Session = Depends(get_db)):
    user = get_user_by_name(db, request.username)
    if not user: raise HTTPException(status_code=404, detail="사용자 없음")
    
    folder = get_folder_by_name(db, user.id, request.folder_name)
    if not folder: raise HTTPException(status_code=404, detail="폴더 없음")
    
    problems = {}
    for p in folder.problems:
        problems[p.id] = {
            "problem": p.problem_text,
            "choices": p.choices,
            "answer": p.correct_answer # 클라이언트 확인용 (실제론 숨겨야 할 수도 있음)
        }
    return {"problems": problems}

@app.post("/solve")
def solve_problem(request: schemas.SolveRequest, db: Session = Depends(get_db)):
    problem = db.query(models.Problem).filter(models.Problem.id == request.problem_id).first()
    if not problem: raise HTTPException(status_code=404, detail="문제 없음")
    
    if problem.correct_answer == request.user_answer:
        return {"result": "정답입니다! 🎉"}
    else:
        return {"result": f"오답입니다. (정답: {problem.correct_answer})"}
    
@app.put("/problems/{problem_id}")
def update_problem(problem_id: str, request: schemas.UpdateProblemRequest, db: Session = Depends(get_db)):
    problem = db.query(models.Problem).filter(models.Problem.id == problem_id).first()
    if not problem: raise HTTPException(status_code=404, detail="문제 없음")
    
    if request.problem_text:
        problem.problem_text = request.problem_text
    if request.correct_answer:
        problem.correct_answer = request.correct_answer
    
    db.commit()
    return {"message": "문제 수정 완료"}

@app.delete("/problems/{problem_id}")
def delete_problem(problem_id: str, db: Session = Depends(get_db)):
    problem = db.query(models.Problem).filter(models.Problem.id == problem_id).first()
    if not problem: raise HTTPException(status_code=404, detail="문제 없음")
    
    db.delete(problem)
    db.commit()
    return {"message": "문제 삭제 완료"}