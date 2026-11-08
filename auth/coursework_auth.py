"""Password verification for the coursework app_user table."""
from datetime import datetime, timezone

from argon2 import PasswordHasher
from argon2.exceptions import VerificationError

from database.connection import get_connection


def verify_coursework_login(username: str, password: str) -> dict | None:
    with get_connection() as conn:
        account = conn.execute("""SELECT u.user_id,u.user_name,u.password_hash,u.account_status,u.role_id,
                    r.role_name,u.judge_id,u.clerk_id,u.lawyer_id,u.court_id,u.locked_until
            FROM app_user u JOIN role r USING(role_id) WHERE lower(u.user_name)=lower(%s)""",
            (username.strip(),)).fetchone()
        if not account or account["account_status"].lower() != "active" or (
            account["locked_until"] and account["locked_until"] > datetime.now(timezone.utc)
        ):
            conn.execute("INSERT INTO auth_event_log(username,event_type,details) VALUES (%s,'LOGIN_FAILURE','Unknown, inactive, or temporarily locked account')",
                         (username.strip() or "(empty)",))
            return None
        try:
            valid = PasswordHasher().verify(account["password_hash"], password)
        except (VerificationError, ValueError, TypeError):
            valid = False
        if not valid:
            conn.execute("""UPDATE app_user SET failed_login_count=failed_login_count+1,
                locked_until=CASE WHEN failed_login_count >= 4 THEN CURRENT_TIMESTAMP + INTERVAL '15 minutes' ELSE locked_until END
                WHERE user_id=%s""", (account["user_id"],))
            conn.execute("INSERT INTO auth_event_log(username,user_id,event_type,details) VALUES (%s,%s,'LOGIN_FAILURE','Password verification failed')",
                         (account["user_name"],account["user_id"]))
            return None
        conn.execute("UPDATE app_user SET last_login_at=CURRENT_TIMESTAMP,failed_login_count=0,locked_until=NULL WHERE user_id=%s",
                     (account["user_id"],))
        conn.execute("INSERT INTO auth_event_log(username,user_id,event_type) VALUES (%s,%s,'LOGIN_SUCCESS')",
                     (account["user_name"],account["user_id"]))
    return {"user_id": account["user_id"], "username": account["user_name"],
            "role_id": account["role_id"], "role_name": account["role_name"],
            "judge_id": account["judge_id"], "clerk_id": account["clerk_id"],
            "lawyer_id": account["lawyer_id"], "court_id": account["court_id"]}
