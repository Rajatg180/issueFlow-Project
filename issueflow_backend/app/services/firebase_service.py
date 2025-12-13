import os
import firebase_admin
from firebase_admin import credentials, auth
from app.core.config import settings

_firebase_app = None


def init_firebase():
    global _firebase_app
    if _firebase_app:
        return _firebase_app

    cred_path = settings.firebase_service_account_file
    if not cred_path or not os.path.exists(cred_path):
        raise RuntimeError(
            "Firebase service account file missing. "
            "Set FIREBASE_SERVICE_ACCOUNT_FILE in .env"
        )

    cred = credentials.Certificate(cred_path)
    _firebase_app = firebase_admin.initialize_app(cred)
    return _firebase_app


def verify_firebase_id_token(id_token: str) -> dict:
    init_firebase()
    return auth.verify_id_token(id_token)
