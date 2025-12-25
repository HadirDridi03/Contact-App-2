from pydantic import BaseModel, EmailStr
from uuid import UUID
from typing import Optional

class UserCreate(BaseModel):
    email: EmailStr
    password: str

class UserOut(BaseModel):
    id: int
    email: EmailStr

class Token(BaseModel):
    access_token: str
    token_type: str

class ContactBase(BaseModel):
    name: str
    email: str
    phone: str

class ContactCreate(ContactBase):
    pass

class ContactUpdate(ContactBase):
    photo_url: Optional[str] = None  # Pour garder l'ancienne photo si pas de nouvelle

class ContactOut(ContactBase):
    id: UUID
    photo_url: Optional[str] = None