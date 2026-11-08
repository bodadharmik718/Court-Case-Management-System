import bcrypt
from argon2 import PasswordHasher
from argon2.exceptions import VerificationError

from database.connection import get_connection


def verify_login(username: str, password: str) -> dict | None:
    """Authenticate an active account using its stored bcrypt hash."""
    with get_connection() as conn:
        row = conn.execute(
            """SELECT user_id, username, password_hash, account_status
               FROM user_account WHERE username = %s""", (username.strip(),)
        ).fetchone()
        if not row or row["account_status"] != "ACTIVE":
            return None
        try:
            stored_hash = row["password_hash"]
            if stored_hash.startswith("$argon2"):
                valid = PasswordHasher().verify(stored_hash, password)
            elif stored_hash.startswith(("$2a$", "$2b$", "$2y$")):
                valid = bcrypt.checkpw(password.encode(), stored_hash.encode())
            else:
                valid = False
        except (VerificationError, ValueError, TypeError):
            return None
        if not valid:
            return None
        conn.execute("UPDATE user_account SET last_login_at = CURRENT_TIMESTAMP WHERE user_id = %s", (row["user_id"],))
        roles = conn.execute(
            """SELECT r.role_code, r.role_name, ura.forum_id, ura.case_id
               FROM user_role_assignment ura JOIN app_role r USING (role_code)
               WHERE ura.user_id = %s AND ura.valid_from <= CURRENT_TIMESTAMP
                 AND (ura.valid_to IS NULL OR ura.valid_to >= CURRENT_TIMESTAMP)""", (row["user_id"],)
        ).fetchall()
    return {"user_id": row["user_id"], "username": row["username"], "roles": roles}
