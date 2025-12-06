from pydantic import BaseModel
from typing import List, Optional

# ------ User ------
# 회원가입 
class UserCreate(BaseModel):
    username: str
    password: str

# 로그인 
class UserLogin(BaseModel):
    username: str
    password: str
    
# 통계 
class UserStatsUpdate(BaseModel):
    username: str
    solved_count: int
    correct_count: int

# ------ Folder ------
# 생성 
class FolderCreate(BaseModel):
    username: str
    folder_name: str
    color: str = "0xFF1E2B58"

# 수정 
class FolderUpdate(BaseModel):
    username: str
    new_name: str
    new_color: str

# ------ Problem ------
class ProblemBase(BaseModel):
    problem: str
    choices: List[str]
    correct_answer: str

# 문제 저장 요청 (OCR 결과 수정본 포함)
class SaveProblemRequest(BaseModel):
    username: str
    temp_id: str                            # OCR 후 발급받은 임시 ID
    folder_id: int 
    correct_answer: str
    problem_text: Optional[str] = None      # 사용자가 수정한 문제 텍스트
    choices: Optional[List[str]] = None     # 사용자가 수정한 선지 
    memo: Optional[str] = None 

class UpdateProblemRequest(BaseModel):
    problem_text: Optional[str] = None
    correct_answer: Optional[str] = None

class SolveRequest(BaseModel):
    user_answer: str        # 정답 체크용 

# ------ Wrong Note (오답노트) ------
class WrongNoteUpdate(BaseModel):
    problem_ids: List[str]
    is_wrong_note: bool     # True: 추가, False: 제거
    
# ------ OCR ------
class OcrRequest(BaseModel):
    username: str
    image_data: str         # Base64 인코딩된 이미지 문자열

# ------ History (시험 결과 기록) ------
class HistoryCreate(BaseModel):
    username: str
    score: int

class HistoryResponse(BaseModel):
    date: str  # "2023-10-25"
    score: int