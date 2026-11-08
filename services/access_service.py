"""Public read models, restricted document access, and admin account linking."""
from pathlib import Path
from argon2 import PasswordHasher

from auth.permissions import require_permission
from auth.permissions import has_permission
from config.settings import settings
from database.connection import get_connection


def public_case_search(term: str = "") -> list[dict]:
    pattern = f"%{term.strip()}%"
    with get_connection() as conn:
        return conn.execute("""SELECT c.cuid,c.cnr,c.case_title,c.case_type,c.filing_date,co.jurisdiction_area AS court,
            (SELECT new_status FROM case_status_history h WHERE h.case_id=c.case_id ORDER BY transition_timestamp DESC LIMIT 1) AS status
            FROM court_case c JOIN court co USING(court_id)
            WHERE c.public_access AND NOT c.is_confidential AND c.archived_at IS NULL
              AND (%s='' OR c.cuid ILIKE %s OR c.cnr ILIKE %s OR c.case_title ILIKE %s OR EXISTS(
                SELECT 1 FROM case_party cp JOIN party p USING(party_id) WHERE cp.case_id=c.case_id AND p.party_name ILIKE %s))
            ORDER BY c.filing_date DESC LIMIT 200""",(term.strip(),pattern,pattern,pattern,pattern)).fetchall()


def public_orders(term: str = "") -> list[dict]:
    pattern = f"%{term.strip()}%"
    with get_connection() as conn:
        rows=conn.execute("""SELECT o.order_id,o.order_type,o.order_content,c.cuid,c.cnr,c.case_title
            FROM court_order o JOIN court_case c USING(case_id)
            WHERE o.is_public AND o.digital_signature_hash IS NOT NULL AND c.public_access AND NOT c.is_confidential AND c.archived_at IS NULL
              AND (%s='' OR c.cuid ILIKE %s OR c.cnr ILIKE %s OR c.case_title ILIKE %s)
            ORDER BY o.order_id DESC LIMIT 100""",(term.strip(),pattern,pattern,pattern)).fetchall()
        judgments=conn.execute("""SELECT j.judgment_id AS order_id,'Judgment' AS order_type,j.verdict_text AS order_content,c.cuid,c.cnr,c.case_title
            FROM judgment j JOIN court_case c USING(case_id)
            WHERE j.is_public AND j.digital_signature_hash IS NOT NULL AND c.public_access AND NOT c.is_confidential AND c.archived_at IS NULL
              AND (%s='' OR c.cuid ILIKE %s OR c.cnr ILIKE %s OR c.case_title ILIKE %s)
            ORDER BY j.judgment_id DESC LIMIT 100""",(term.strip(),pattern,pattern,pattern)).fetchall()
        return list(rows)+list(judgments)


def set_case_public(*, user: dict, case_id: int, publish: bool) -> None:
    require_permission(user,"CASE_PUBLISH",case_id=case_id)
    with get_connection() as conn:
        result = conn.execute("UPDATE court_case SET public_access=%s WHERE case_id=%s AND archived_at IS NULL AND is_confidential=FALSE",(publish,case_id))
        if not result.rowcount:
            raise ValueError("Case not found, archived, or marked confidential; it cannot be published.")
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES (%s,%s,%s,'PUBLICATION','court_case',%s,%s)",("CASE_PUBLISHED" if publish else "CASE_UNPUBLISHED",user["user_id"],case_id,case_id,str(publish)))


def public_document(document_id: int) -> tuple[str, bytes] | None:
    with get_connection() as conn:
        row = conn.execute("""SELECT d.title,d.file_path FROM document d JOIN court_case c USING(case_id)
            WHERE d.document_id=%s AND d.is_public AND c.public_access AND NOT c.is_confidential AND c.archived_at IS NULL""",(document_id,)).fetchone()
        if not row:
            return None
    root_config = settings.document_storage_path
    root = (root_config if root_config.is_absolute() else Path(__file__).resolve().parents[1] / root_config).resolve()
    path = Path(row["file_path"]).resolve()
    if root not in path.parents or not path.is_file():
        return None
    return row["title"],path.read_bytes()


def private_document(document_id: int, *, user: dict) -> tuple[str, bytes] | None:
    with get_connection() as conn:
        row=conn.execute("SELECT document_id,title,file_path,case_id,is_public FROM document WHERE document_id=%s",(document_id,)).fetchone()
    if not row:
        return None
    if not row["is_public"]:
        require_permission(user,"DOCUMENT_PRIVATE_READ",case_id=row["case_id"])
    elif not has_permission(user,"DOCUMENT_PRIVATE_READ",case_id=row["case_id"]):
        # Publicly marked documents remain readable only through their public case.
        with get_connection() as conn:
            allowed=conn.execute("SELECT EXISTS(SELECT 1 FROM court_case WHERE case_id=%s AND public_access AND NOT is_confidential AND archived_at IS NULL) AS ok",(row["case_id"],)).fetchone()["ok"]
        if not allowed:
            return None
    root_config=settings.document_storage_path
    root=(root_config if root_config.is_absolute() else Path(__file__).resolve().parents[1]/root_config).resolve()
    path=Path(row["file_path"]).resolve()
    if root not in path.parents or not path.is_file():
        return None
    return row["title"],path.read_bytes()


def admin_users(*, user: dict) -> list[dict]:
    require_permission(user,"USER_ADMIN")
    with get_connection() as conn:
        return conn.execute("""SELECT u.user_id,u.user_name,u.email,u.account_status,u.role_id,r.role_name,
            u.judge_id,u.clerk_id,u.lawyer_id,u.court_id FROM app_user u JOIN role r USING(role_id) ORDER BY u.user_id""").fetchall()


def profile_options(*, user: dict) -> dict[str,list[dict]]:
    require_permission(user,"USER_ADMIN")
    with get_connection() as conn:
        return {
            "roles":conn.execute("SELECT role_id,role_name FROM role ORDER BY role_name").fetchall(),
            "judges":conn.execute("SELECT judge_id,judge_name FROM judge ORDER BY judge_name").fetchall(),
            "clerks":conn.execute("SELECT clerk_id,clerk_name FROM court_clerk ORDER BY clerk_name").fetchall(),
            "lawyers":conn.execute("SELECT lawyer_id,full_name FROM lawyer ORDER BY full_name").fetchall(),
            "courts":conn.execute("SELECT court_id,jurisdiction_area FROM court ORDER BY jurisdiction_area").fetchall(),
        }


def update_user_access(*, user: dict, target_user_id: int, role_id: int, status: str,
                       judge_id: int | None, clerk_id: int | None, lawyer_id: int | None, court_id: int | None) -> None:
    require_permission(user,"USER_ADMIN")
    if status not in {"Active","Locked","Inactive"}:
        raise ValueError("Select a supported account status.")
    with get_connection() as conn:
        conn.execute("""UPDATE app_user SET role_id=%s,account_status=%s,judge_id=%s,clerk_id=%s,lawyer_id=%s,court_id=%s
            WHERE user_id=%s""",(role_id,status,judge_id,clerk_id,lawyer_id,court_id,target_user_id))
        conn.execute("""INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state)
            VALUES ('USER_ACCESS_UPDATED',%s,NULL,'ADMIN','app_user',%s,%s)""",
            (user["user_id"],target_user_id,f'role={role_id}; status={status}; profile links updated'))


def create_user(*, user: dict, username: str, password: str, role_id: int, email: str = "", phone: str = "",
                judge_id: int | None = None, clerk_id: int | None = None, lawyer_id: int | None = None, court_id: int | None = None) -> int:
    require_permission(user,"USER_ADMIN")
    if len(username.strip())<3 or len(password)<12:
        raise ValueError("Username must have at least 3 characters and password at least 12 characters.")
    password_hash=PasswordHasher().hash(password)
    with get_connection() as conn:
        row=conn.execute("""INSERT INTO app_user(user_name,email,phone,account_status,role_id,password_hash,judge_id,clerk_id,lawyer_id,court_id)
            VALUES (%s,%s,%s,'Active',%s,%s,%s,%s,%s,%s) RETURNING user_id""",
            (username.strip(),email.strip() or None,phone.strip() or None,role_id,password_hash,judge_id,clerk_id,lawyer_id,court_id)).fetchone()
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES ('USER_CREATED',%s,NULL,'ADMIN','app_user',%s,%s)",(user["user_id"],row["user_id"],f'username={username.strip()}; role={role_id}'))
        return row["user_id"]
