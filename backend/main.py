from fastapi import FastAPI, Depends, HTTPException, status, UploadFile, File, Form, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from sqlalchemy.orm import Session
from uuid import uuid4
import os
import shutil

from database import get_db, Base, engine
from models import User, Contact
from schemas import UserCreate, Token, ContactOut
from auth import get_current_user, get_password_hash, verify_password, create_access_token

Base.metadata.create_all(bind=engine)

app = FastAPI(title="Contacts API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_FOLDER = os.getenv("UPLOAD_FOLDER", "uploads")
uploads_path = os.path.join(os.path.dirname(__file__), UPLOAD_FOLDER)
os.makedirs(uploads_path, exist_ok=True)

app.mount("/uploads", StaticFiles(directory=uploads_path), name="uploads")


@app.post("/register", response_model=Token)
async def register(request: Request, db: Session = Depends(get_db)):
    data = await request.json()
    email = data.get("email")
    password = data.get("password")
    if not email or not password:
        raise HTTPException(status_code=400, detail="Email et mot de passe requis")
    db_user = db.query(User).filter(User.email == email).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email déjà utilisé")
    hashed = get_password_hash(password)
    new_user = User(email=email, hashed_password=hashed)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    token = create_access_token({"sub": str(new_user.id)})
    return {"access_token": token, "token_type": "bearer"}


@app.post("/login", response_model=Token)
async def login(request: Request, db: Session = Depends(get_db)):
    data = await request.json()
    email = data.get("email")
    password = data.get("password")
    if not email or not password:
        raise HTTPException(status_code=400, detail="Email et mot de passe requis")
    user = db.query(User).filter(User.email == email).first()
    if not user or not verify_password(password, user.hashed_password):
        raise HTTPException(status_code=400, detail="Email ou mot de passe incorrect")
    token = create_access_token({"sub": str(user.id)})
    return {"access_token": token, "token_type": "bearer"}


@app.get("/contacts", response_model=list[ContactOut])
def get_contacts(current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(Contact).filter(Contact.user_id == current_user.id).order_by(Contact.name).all()


@app.get("/contacts/search")
def search_contacts(q: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    return db.query(Contact).filter(
        Contact.user_id == current_user.id,
        Contact.name.ilike(f"%{q}%")
    ).order_by(Contact.name).all()


@app.post("/contacts", response_model=ContactOut)
async def create_contact(
    name: str = Form(...),
    email: str = Form(...),
    phone: str = Form(...),
    photo: UploadFile = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    photo_url = None
    if photo and photo.filename:
        file_ext = photo.filename.split(".")[-1] if "." in photo.filename else ""
        filename = f"{uuid4()}.{file_ext}"
        path = os.path.join(uploads_path, filename)
        with open(path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)
        photo_url = f"/uploads/{filename}"

    contact = Contact(
        user_id=current_user.id,
        name=name,
        email=email,
        phone=phone,
        photo_url=photo_url
    )
    db.add(contact)
    db.commit()
    db.refresh(contact)
    return contact


@app.put("/contacts/{contact_id}", response_model=ContactOut)
async def update_contact(
    contact_id: str,
    name: str = Form(...),
    email: str = Form(...),
    phone: str = Form(...),
    photo: UploadFile = File(None),
    current_user: User = Depends(get_current_user),
    db: Session = Depends(get_db)
):
    contact = db.query(Contact).filter(Contact.id == contact_id, Contact.user_id == current_user.id).first()
    if not contact:
        raise HTTPException(status_code=404, detail="Contact non trouvé")

    photo_url = contact.photo_url
    if photo and photo.filename:
        file_ext = photo.filename.split(".")[-1] if "." in photo.filename else ""
        filename = f"{uuid4()}.{file_ext}"
        path = os.path.join(uploads_path, filename)
        with open(path, "wb") as buffer:
            shutil.copyfileobj(photo.file, buffer)
        photo_url = f"/uploads/{filename}"

    contact.name = name
    contact.email = email
    contact.phone = phone
    contact.photo_url = photo_url
    db.commit()
    db.refresh(contact)
    return contact


@app.delete("/contacts/{contact_id}")
def delete_contact(contact_id: str, current_user: User = Depends(get_current_user), db: Session = Depends(get_db)):
    contact = db.query(Contact).filter(Contact.id == contact_id, Contact.user_id == current_user.id).first()
    if not contact:
        raise HTTPException(status_code=404, detail="Contact non trouvé")
    db.delete(contact)
    db.commit()
    return {"message": "Contact supprimé"}