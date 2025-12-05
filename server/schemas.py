from pydantic import BaseModel
from typing import List, Optional

# ------ User ------
class UserCreate(BaseModel):
    username: str
    password: str

class UserLogin(BaseModel):
    username: str
    password: str
    
class UserStatsUpdate(BaseModel):
    username: str
    solved_count: int
    correct_count: int

# ------ Folder ------
class FolderCreate(BaseModel):
    username: str
    folder_name: str
    color: str = "0xFF1E2B58"

class FolderUpdate(BaseModel):
    username: str
    new_name: str
    new_color: str

# ------ Problem ------
class ProblemBase(BaseModel):
    problem: str
    choices: List[str]
    correct_answer: str

class SaveProblemRequest(BaseModel):
    username: str
    temp_id: str
    folder_id: int # folder_name 대신 ID로 명확하게
    correct_answer: str
    problem_text: Optional[str] = None
    choices: Optional[List[str]] = None
    memo: Optional[str] = None 

class UpdateProblemRequest(BaseModel):
    problem_text: Optional[str] = None
    correct_answer: Optional[str] = None

class SolveRequest(BaseModel):
    user_answer: str        # 정답 체크용 

# ------ Wrong Note ------
class WrongNoteUpdate(BaseModel):
    problem_ids: List[str]
    is_wrong_note: bool 
    
# ------ OCR ------
class OcrRequest(BaseModel):
    username: str
    image_data: str