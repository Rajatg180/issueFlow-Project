from pydantic import BaseModel
from typing import List


class UserMiniResponse(BaseModel):
    id: str
    username: str


class ProjectUsersResponse(BaseModel):
    users: List[UserMiniResponse]
