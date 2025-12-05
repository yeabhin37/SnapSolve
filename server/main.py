import os
import base64
import uuid
import re
import json
import time
import requests
from fastapi import FastAPI, HTTPException, Depends, Query
from sqlalchemy.orm import Session 
from typing import List, Dict
from database import engine, Base, get_db
import models, schemas 
from passlib.context import CryptContext

models.Base.metadata.drop_all(bind=engine)   # 데이터베이스 초기화. 필요시 주석 해제하기 
models.Base.metadata.create_all(bind=engine)

app = FastAPI()

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
temp_ocr_results = {} # OCR 미리보기 결과를 임시 저장하는 곳

# ------ Helper Functions ------
def get_user_by_name(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first() 

def get_folder_by_id(db: Session, folder_id: int):
    return db.query(models.Folder).filter(models.Folder.id == folder_id).first()

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


# ---------------------------------------
#        RESTful API Endpoints 
# ---------------------------------------

# ------ Auth ------
@app.post("/register", status_code=201)
def register_user(request: schemas.UserCreate, db: Session = Depends(get_db)):
    if get_user_by_name(db, request.username):
        raise HTTPException(status_code=400, detail="이미 존재하는 사용자입니다.")
    hashed_password = pwd_context.hash(request.password)
    new_user = models.User(username=request.username, password_hash=hashed_password)
    db.add(new_user)
    db.commit()
    return {"message": "회원가입 성공"}

@app.post("/login")
def login_user(request: schemas.UserLogin, db: Session = Depends(get_db)):
    user = get_user_by_name(db, request.username)
    if not user or not pwd_context.verify(request.password, user.password_hash):
        raise HTTPException(status_code=401, detail="로그인 실패")
    return {"message": "로그인 성공", "username": user.username}

# ------ Folders ------
# 폴더 목록 조회 (GET)
@app.get("/folders")
def get_folders(username: str = Query(...), db: Session = Depends(get_db)):
    user = get_user_by_name(db, username)
    if not user: raise HTTPException(status_code=404, detail="사용자 없음")
    
    return {"folders": [
        {
            "id": f.id,
            "name": f.name, 
            "color": f.color, 
            "problem_count": len(f.problems)
        } for f in user.folders
    ]}

# 폴더 생성 (POST)
@app.post("/folders", status_code=201)
def create_folder(request: schemas.FolderCreate, db: Session = Depends(get_db)):
    user = get_user_by_name(db, request.username)
    if not user: raise HTTPException(status_code=404, detail="사용자 없음")
    
    # 중복 체크 로직은 MVP에서 생략 가능하나 있으면 좋음
    new_folder = models.Folder(name=request.folder_name, user_id=user.id, color=request.color)
    db.add(new_folder)
    db.commit()
    return {"message": "폴더 생성 완료", "id": new_folder.id}

# 폴더 수정 (PUT) 
@app.put("/folders/{folder_id}")
def update_folder(folder_id: int, request: schemas.FolderUpdate, db: Session = Depends(get_db)):
    folder = get_folder_by_id(db, folder_id)
    if not folder: raise HTTPException(status_code=404, detail="폴더 없음")
    # (실제론 username으로 소유권 확인 로직 필요)
    
    folder.name = request.new_name
    folder.color = request.new_color
    db.commit()
    return {"message": "수정 완료"}

# 폴더 삭제 (DELETE)
@app.delete("/folders/{folder_id}")
def delete_folder(folder_id: int, username: str = Query(...), db: Session = Depends(get_db)):
    folder = get_folder_by_id(db, folder_id)
    if not folder: raise HTTPException(status_code=404, detail="폴더 없음")
    # 소유권 확인
    user = get_user_by_name(db, username)
    if folder.user_id != user.id: raise HTTPException(status_code=403, detail="권한 없음")

    db.delete(folder)
    db.commit()
    return {"message": "삭제 완료"}

# ------ OCR ------
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

# ------ Problems ------
@app.post("/problems", status_code=201)
def save_problem(request: schemas.SaveProblemRequest, db: Session = Depends(get_db)):
    if request.temp_id not in temp_ocr_results:
        raise HTTPException(status_code=404, detail="임시 데이터 만료")
    
    ocr_data = temp_ocr_results.pop(request.temp_id)
    folder = get_folder_by_id(db, request.folder_id)
    if not folder: raise HTTPException(status_code=404, detail="폴더 없음")

    final_text = request.problem_text if request.problem_text else ocr_data['problem']
    final_choices = request.choices if request.choices else ocr_data['choices']

    new_prob = models.Problem(
        problem_text=final_text,
        choices=final_choices,
        correct_answer=request.correct_answer,
        folder_id=folder.id
    )
    db.add(new_prob)
    db.commit()
    return {"message": "저장 완료", "id": new_prob.id}

# 문제 목록 조회 (GET) 
@app.get("/problems")
def get_problems(folder_id: int = Query(...), db: Session = Depends(get_db)):
    folder = get_folder_by_id(db, folder_id)
    if not folder: raise HTTPException(status_code=404, detail="폴더 없음")
    
    problems = {}
    for p in folder.problems:
        problems[p.id] = {
            "problem": p.problem_text,
            "choices": p.choices,
            "answer": p.correct_answer,
            "is_wrong_note": p.is_wrong_note
        }
    return {"problems": problems}

# 문제 수정 (PUT)
@app.put("/problems/{problem_id}")
def update_problem(problem_id: str, request: schemas.UpdateProblemRequest, db: Session = Depends(get_db)):
    problem = db.query(models.Problem).filter(models.Problem.id == problem_id).first()
    if not problem: raise HTTPException(status_code=404, detail="문제 없음")
    
    if request.problem_text: problem.problem_text = request.problem_text
    if request.correct_answer: problem.correct_answer = request.correct_answer
    db.commit()
    return {"message": "수정 완료"}

# 문제 삭제 (DELETE) 
@app.delete("/problems/{problem_id}")
def delete_problem(problem_id: str, db: Session = Depends(get_db)):
    problem = db.query(models.Problem).filter(models.Problem.id == problem_id).first()
    if not problem: raise HTTPException(status_code=404, detail="문제 없음")
    
    db.delete(problem)
    db.commit()
    return {"message": "문제 삭제 완료"}

# 문제 정답 확인 (채점)
@app.post("/problems/{problem_id}/check")
def check_answer(problem_id: str, request: schemas.SolveRequest, db: Session = Depends(get_db)):
    problem = db.query(models.Problem).filter(models.Problem.id == problem_id).first()
    if not problem: raise HTTPException(status_code=404, detail="문제 없음")
    
    is_correct = (problem.correct_answer == request.user_answer)
    return {"result": "정답" if is_correct else "오답", "is_correct": is_correct}


# ------ Wrong Notes ------

# 10. 오답노트 조회 (GET)
@app.get("/wrong-notes")
def get_wrong_notes(username: str = Query(...), db: Session = Depends(get_db)):
    user = get_user_by_name(db, username)
    if not user: raise HTTPException(status_code=404, detail="사용자 없음")
    
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

#  오답노트 상태 일괄 변경 (PATCH) -> 부분 업데이트 의미
@app.patch("/problems/wrong-note")
def bulk_update_wrong_note(request: schemas.WrongNoteUpdate, db: Session = Depends(get_db)):
    db.query(models.Problem).\
        filter(models.Problem.id.in_(request.problem_ids)).\
        update({models.Problem.is_wrong_note: request.is_wrong_note}, synchronize_session=False)
    db.commit()
    return {"message": "업데이트 완료"}