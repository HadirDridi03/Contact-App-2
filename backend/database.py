from sqlalchemy import create_engine
from sqlalchemy.ext.declarative import declarative_base
from sqlalchemy.orm import sessionmaker
from dotenv import load_dotenv
import os

# Chemin absolu vers le dossier backend (où se trouve .env)
current_dir = os.path.dirname(os.path.abspath(__file__))
env_path = os.path.join(current_dir, '.env')

# Chargement explicite du .env avec le chemin absolu
load_dotenv(dotenv_path=env_path)

# Récupération de la variable
SQLALCHEMY_DATABASE_URL = os.getenv("DATABASE_URL")

# Debug temporaire (tu verras ça dans la console)
print(f"Fichier .env chargé depuis : {env_path}")
print(f"DATABASE_URL = {SQLALCHEMY_DATABASE_URL}")

if SQLALCHEMY_DATABASE_URL is None:
    raise ValueError("⚠️ DATABASE_URL n'est toujours pas définie ! Vérifie le chemin et le contenu du .env")

engine = create_engine(SQLALCHEMY_DATABASE_URL)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

Base = declarative_base()

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()