from sqlalchemy.orm import Session
import models

# ------ Helper Functions ------
# 사용자 이름으로 사용자 객체 조회
def get_user_by_name(db: Session, username: str):
    return db.query(models.User).filter(models.User.username == username).first() 

# 폴더 ID로 폴더 객체 조회
def get_folder_by_id(db: Session, folder_id: int):
    return db.query(models.Folder).filter(models.Folder.id == folder_id).first()
