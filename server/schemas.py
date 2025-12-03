from pydantic import BaseModel
from typing import List, Optional

class UserCreate(BaseModel):
    username: str
    password: str

class UserLogin(BaseModel):
    username: str
    password: str
    
class FolderCreate(BaseModel):
    username: str
    folder_name: str
    color: str = "0xFF1E2B58"

class FolderUpdate(BaseModel):
    username: str
    folder_id: int
    new_name: str
    new_color: str

class FolderDelete(BaseModel):
    username: str
    folder_id: int

class FolderResponse(BaseModel):
    id: int
    name: str

class ProblemBase(BaseModel):
    problem: str
    choices: List[str]
    correct_answer: str

class ProblemResponse(ProblemBase):
    id: str
    class Config:
        from_attributes = True

class SaveRequest(BaseModel):
    username: str
    temp_id: str
    folder_name: str
    correct_answer: str
    problem_text: Optional[str] = None

class SolveRequest(BaseModel):
    username: str
    problem_id: str
    user_answer: str

class UpdateProblemRequest(BaseModel):
    problem_text: Optional[str] = None
    correct_answer: Optional[str] = None

class OcrRequest(BaseModel):
    username: str
    image_data: str