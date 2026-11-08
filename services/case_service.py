from datetime import date

from auth.authorization import require_permission
from repositories.case_repository import create_case, list_cases, case_details, lookups, transition_case, transfer_case, update_case_details


def search_cases(user: dict, query: str = "", *, limit: int = 100, offset: int = 0) -> list[dict]:
    # Scope to active role assignments, lawyer representation, party relationship,
    # or public documents for public users. Confidential records are excluded by default.
    rows = list_cases(query, limit, offset)
    from database.connection import get_connection
    with get_connection() as conn:
        visible = conn.execute(
            """SELECT DISTINCT c.case_id FROM case_file c
               WHERE c.is_confidential = FALSE AND (
                 EXISTS (SELECT 1 FROM user_role_assignment ura JOIN role_permission rp USING(role_code) WHERE ura.user_id=%s AND rp.permission_code='CASE_READ' AND ura.valid_from<=CURRENT_TIMESTAMP AND (ura.valid_to IS NULL OR ura.valid_to>=CURRENT_TIMESTAMP) AND (ura.case_id=c.case_id OR (ura.role_code IN ('COURT_ADMIN','REGISTRY_CLERK') AND ura.forum_id=c.current_forum_id) OR (ura.role_code IN ('SUPER_ADMIN','AUDITOR') AND ura.forum_id IS NULL AND ura.case_id IS NULL)))
                 OR EXISTS (SELECT 1 FROM user_account u JOIN judge_profile jp ON jp.person_id=u.person_id JOIN judge_bench_assignment jba USING(judge_id) JOIN hearing h USING(bench_id) WHERE u.user_id=%s AND h.case_id=c.case_id AND jba.start_date<=h.hearing_date AND (jba.end_date IS NULL OR jba.end_date>=h.hearing_date) AND EXISTS (SELECT 1 FROM user_role_assignment ura JOIN role_permission rp USING(role_code) WHERE ura.user_id=u.user_id AND rp.permission_code='CASE_READ' AND ura.role_code='JUDGE' AND ura.valid_from<=CURRENT_TIMESTAMP AND (ura.valid_to IS NULL OR ura.valid_to>=CURRENT_TIMESTAMP)))
                 OR EXISTS (SELECT 1 FROM user_account u JOIN lawyer_profile lp ON lp.person_id=u.person_id JOIN lawyer_representation lr USING(lawyer_id) JOIN case_party cp USING(case_party_id) WHERE u.user_id=%s AND cp.case_id=c.case_id AND lr.ended_on IS NULL AND lr.representation_status='ACTIVE' AND EXISTS (SELECT 1 FROM user_role_assignment ura JOIN role_permission rp USING(role_code) WHERE ura.user_id=u.user_id AND rp.permission_code='CASE_READ' AND ura.valid_from<=CURRENT_TIMESTAMP AND (ura.valid_to IS NULL OR ura.valid_to>=CURRENT_TIMESTAMP)))
                 OR EXISTS (SELECT 1 FROM user_account u JOIN party p ON p.person_id=u.person_id JOIN case_party cp USING(party_id) WHERE u.user_id=%s AND cp.case_id=c.case_id AND EXISTS (SELECT 1 FROM user_role_assignment ura JOIN role_permission rp USING(role_code) WHERE ura.user_id=u.user_id AND rp.permission_code='CASE_READ' AND ura.valid_from<=CURRENT_TIMESTAMP AND (ura.valid_to IS NULL OR ura.valid_to>=CURRENT_TIMESTAMP)))
                 OR (EXISTS (SELECT 1 FROM user_role_assignment ura JOIN role_permission rp USING(role_code) WHERE ura.user_id=%s AND rp.permission_code='CASE_READ' AND ura.valid_from<=CURRENT_TIMESTAMP AND (ura.valid_to IS NULL OR ura.valid_to>=CURRENT_TIMESTAMP)) AND EXISTS (SELECT 1 FROM document d WHERE d.case_id=c.case_id AND d.public_visible=TRUE AND d.confidentiality_level='PUBLIC' AND d.is_active))
               )""", (user["user_id"], user["user_id"], user["user_id"], user["user_id"], user["user_id"])
        ).fetchall()
    allowed = {r["case_id"] for r in visible}
    return [row for row in rows if row["case_id"] in allowed]


def get_case(user: dict, case_id: int) -> dict | None:
    require_permission(user["user_id"], "CASE_READ", case_id=case_id)
    records = search_cases(user, limit=1000)
    if not any(int(row["case_id"]) == case_id for row in records):
        raise PermissionError("This case is outside your access scope.")
    result = case_details(case_id)
    if result:
        from auth.authorization import has_permission
        if not has_permission(user["user_id"], "DOCUMENT_PRIVATE_READ", case_id=case_id):
            result["documents"] = [row for row in result["documents"] if row["public_visible"] and row["confidentiality_level"] == "PUBLIC"]
    if result and any(role["role_code"] == "PUBLIC_USER" for role in user["roles"]):
        # Public accounts see only the minimum case summary plus explicitly public documents.
        from database.connection import get_connection
        with get_connection() as conn:
            result["documents"] = conn.execute(
                "SELECT document_id,title,document_type_code,confidentiality_level,public_visible FROM document WHERE case_id=%s AND is_active AND public_visible AND confidentiality_level='PUBLIC' ORDER BY created_at DESC",
                (case_id,),
            ).fetchall()
        for section in ("parties", "lawyers", "hearings", "filings", "evidence", "orders", "status_history", "transfers"):
            result[section] = []
        case = result["case"]
        result["case"] = {key: case[key] for key in ("case_id", "cnr", "case_title", "case_type_name", "current_forum_name", "filing_date")}
    return result


def register_case(user: dict, *, title: str, case_type_id: int, forum_id: int, filing_date: date,
                  cnr: str | None, summary: str | None) -> int:
    require_permission(user["user_id"], "CASE_CREATE", forum_id=forum_id)
    if not title.strip():
        raise ValueError("Case title is required.")
    if filing_date > date.today():
        raise ValueError("Filing date cannot be in the future.")
    return create_case(title=title, case_type_id=case_type_id, forum_id=forum_id,
                       filing_date=filing_date, cnr=cnr, summary=summary, user_id=user["user_id"])


def change_status(user: dict, case_id: int, status_code: str, remarks: str) -> None:
    require_permission(user["user_id"], "CASE_UPDATE", case_id=case_id)
    if not remarks.strip():
        raise ValueError("A reason is required for a status change.")
    transition_case(case_id, status_code, user["user_id"], remarks.strip())


def transfer(user: dict, case_id: int, forum_id: int, on_date: date, reason: str) -> None:
    require_permission(user["user_id"], "CASE_TRANSFER", case_id=case_id)
    if not reason.strip() or not on_date:
        raise ValueError("Transfer date and reason are required.")
    transfer_case(case_id, forum_id, on_date, reason, user["user_id"])


def update_case(user: dict, case_id: int, *, title: str, summary: str | None,
                court_value: float | None, language_code: str | None,
                is_confidential: bool) -> int:
    require_permission(user["user_id"], "CASE_UPDATE", case_id=case_id)
    if not title.strip() or len(title.strip()) > 500:
        raise ValueError("Case title is required and must be 500 characters or fewer.")
    if court_value is not None and court_value < 0:
        raise ValueError("Court value cannot be negative.")
    if language_code and len(language_code) > 20:
        raise ValueError("Language code must be 20 characters or fewer.")
    return update_case_details(case_id, title=title.strip(), summary=summary or None,
                               court_value=court_value, language_code=language_code or None,
                               is_confidential=is_confidential)
