from fastapi import APIRouter, Depends, HTTPException, Header
from sqlalchemy.orm import Session

from app.database import get_db
from app.models import User
from app.schemas import UserProfileResponse
from app.auth import decode_token

router = APIRouter(prefix="/users", tags=["users"])


def get_current_user(
    authorization: str = Header(None),
    db: Session = Depends(get_db),
) -> User:
    if not authorization or not authorization.startswith("Bearer "):
        raise HTTPException(status_code=401, detail="Missing token")

    token = authorization.split(" ", 1)[1]

    try:
        payload = decode_token(token)
        user_id = int(payload["sub"])
    except Exception:
        raise HTTPException(status_code=401, detail="Invalid token")

    user = db.query(User).filter(User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=401, detail="User not found")

    return user


@router.get("/me", response_model=UserProfileResponse)
def me(current_user: User = Depends(get_current_user)):
    return UserProfileResponse(
        user_name=current_user.name,
        user_email=current_user.email,
    )