from .db import db
from dataclasses import dataclass

@dataclass
class Users(db.Model):
    """Users table
    """
    user_id: int = db.Column(db.Integer, primary_key=True)
    user_name: str = db.Column(db.String(50), nullable=False)
    user_email: str = db.Column(db.String(120), unique=True, nullable=False) 
    user_password: str = db.Column(db.String(128), nullable=False)

