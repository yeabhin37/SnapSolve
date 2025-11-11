# SnapSolve/server/main.py

import os
import base64
import uuid
import re
import json
import time
import cv2
import numpy as np
import requests
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Dict

# --- 초기 설정 ---
BASE_DIR = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(BASE_DIR, ".env")
load_dotenv(dotenv_path=env_path)
app = FastAPI()

# --- 가상 데이터베이스 및 임시 저장소 (이전 구조와 동일) ---
# {'username': {'folders': {'folder_name': {'problem_id': {...}}}}}
fake_db = {} 
temp_ocr_results = {} # OCR 미리보기 결과를 임시 저장하는 곳

# --- 데이터 모델 정의 (이전 구조와 동일) ---
class UserRequest(BaseModel): username: str
class FolderRequest(BaseModel): username: str; folder_name: str
class OcrRequest(BaseModel): username: str; image_data: str # Base64 인코딩된 이미지
class SaveRequest(BaseModel): username: str; temp_id: str; folder_name: str; correct_answer: str
class SolveRequest(BaseModel): username: str; problem_id: str; user_answer: str

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
            if re.fullmatch(r'[①②③④]|\d', text)
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


# --- API 엔드포인트 (이전 구조와 동일) ---
@app.post("/register")
def register_user(request: UserRequest):
    if request.username in fake_db: raise HTTPException(status_code=400, detail="이미 존재하는 사용자입니다.")
    fake_db[request.username] = {"folders": {}}
    return {"message": f"'{request.username}'님, 환영합니다!"}

@app.post("/create-folder")
def create_folder(request: FolderRequest):
    user_data = fake_db.get(request.username)
    if not user_data: raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    if request.folder_name in user_data["folders"]: raise HTTPException(status_code=400, detail="이미 존재하는 폴더입니다.")
    user_data["folders"][request.folder_name] = {}
    return {"message": f"'{request.folder_name}' 폴더를 성공적으로 생성했습니다."}

@app.post("/ocr") 
def ocr_problem(request: OcrRequest): # 함수명 및 요청 모델명 변경
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
def save_problem(request: SaveRequest): # 함수명 및 요청 모델명 변경
    if request.temp_id not in temp_ocr_results: raise HTTPException(status_code=404, detail="임시 OCR 결과를 찾을 수 없습니다.")
    user_data = fake_db.get(request.username)
    if user_data is None: raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    ocr_data = temp_ocr_results.pop(request.temp_id)
    if request.folder_name not in user_data["folders"]: user_data["folders"][request.folder_name] = {}
    problem_id = str(uuid.uuid4())
    user_data["folders"][request.folder_name][problem_id] = {**ocr_data, "correct_answer": request.correct_answer}
    return {"message": "문제가 성공적으로 저장되었습니다.", "problem_id": problem_id}

@app.post("/folders")
def get_folders(request: UserRequest):
    user_data = fake_db.get(request.username)
    if not user_data: raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")
    return {"folders": list(user_data["folders"].keys())}

@app.post("/problems")
def get_problems_in_folder(request: FolderRequest):
    user_data = fake_db.get(request.username)
    if not user_data or request.folder_name not in user_data["folders"]:
        raise HTTPException(status_code=404, detail="사용자 또는 폴더를 찾을 수 없습니다.")
    
    problems = user_data["folders"][request.folder_name]

    # 문제 텍스트만 보내는 대신, 문제와 선지를 함께 담아서 반환하도록 수정
    problem_details = {}
    for pid, data in problems.items():
        problem_details[pid] = {
            "problem": data.get("problem", "내용 없음"), # .get()으로 안전하게 접근
            "choices": data.get("choices", [])
        }
    
    return {"problems": problem_details}

@app.post("/solve")
def solve_problem(request: SolveRequest):
    # 요청에 포함된 username으로 사용자를 먼저 찾음
    user_data = fake_db.get(request.username)
    if not user_data:
        raise HTTPException(status_code=404, detail="사용자를 찾을 수 없습니다.")

    # 해당 사용자의 모든 폴더를 확인하며 문제 ID를 검색
    for folder, problems in user_data["folders"].items():
        if request.problem_id in problems:
            problem_data = problems[request.problem_id]
            if problem_data["correct_answer"] == request.user_answer:
                return {"result": "정답입니다! 🎉"}
            else:
                return {"result": f"오답입니다. (정답: {problem_data['correct_answer']})"}
    
    # 사용자의 어떤 폴더에서도 문제를 찾지 못한 경우
    raise HTTPException(status_code=404, detail="해당 사용자의 문제 목록에 없는 ID입니다.")