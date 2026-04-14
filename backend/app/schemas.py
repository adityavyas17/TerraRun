from datetime import datetime
from pydantic import BaseModel, EmailStr, Field


class SignupRequest(BaseModel):
    name: str = Field(min_length=2, max_length=100)
    email: EmailStr
    password: str = Field(min_length=6, max_length=100)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=100)


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_name: str
    user_email: EmailStr


class RunCreateRequest(BaseModel):
    distance_km: float = Field(ge=0)
    duration_seconds: int = Field(ge=0)
    avg_speed: float = Field(ge=0)


class RunResponse(BaseModel):
    id: int
    user_id: int
    distance_km: float
    duration_seconds: int
    avg_speed: float
    created_at: datetime

    class Config:
        from_attributes = True


class ProfileStatsResponse(BaseModel):
    total_distance_km: float
    total_runs: int
    avg_speed: float