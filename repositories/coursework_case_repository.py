"""Database operations for the 31-table CCMS coursework schema."""
from datetime import date, datetime, timezone

from database.connection import get_connection
from auth.permissions import has_permission, require_permission


def get_dashboard_summary(*, user: dict) -> dict:
    require_permission(user,"REPORT_VIEW")
    with get_connection() as conn:
        return conn.execute("""SELECT
            (SELECT COUNT(*) FROM court_case WHERE archived_at IS NULL) AS total_cases,
            (SELECT COUNT(*) FROM court) AS courts,
            (SELECT COUNT(*) FROM hearing WHERE hearing_date >= CURRENT_DATE) AS upcoming_hearings,
            (SELECT COUNT(*) FROM hearing WHERE hearing_date = CURRENT_DATE) AS today_hearings,
            (SELECT COUNT(*) FROM filing_defect WHERE lower(cure_status) IN ('open','pending','under review')) AS open_defects,
            (SELECT COUNT(*) FROM petition WHERE filing_status='PENDING_SCRUTINY') AS pending_scrutiny,
            (SELECT COUNT(*) FROM court_case WHERE archived_at IS NOT NULL) AS archived_cases,
            (SELECT COUNT(*) FROM judge) AS judges,
            (SELECT COUNT(*) FROM lawyer) AS advocates,
            (SELECT COUNT(*) FROM party) AS parties,
            (SELECT COUNT(*) FROM court_case c WHERE archived_at IS NULL AND (SELECT new_status FROM case_status_history h WHERE h.case_id=c.case_id ORDER BY transition_timestamp DESC LIMIT 1)='Disposed') AS disposed_cases,
            (SELECT COUNT(*) FROM court_case c WHERE archived_at IS NULL AND (SELECT new_status FROM case_status_history h WHERE h.case_id=c.case_id ORDER BY transition_timestamp DESC LIMIT 1) IN ('Under Hearing','Hearing')) AS cases_under_hearing""").fetchone()


def get_cases(search: str = "", limit: int = 100, offset: int = 0, *, user: dict) -> list[dict]:
    require_permission(user, "CASE_READ")
    term = f"%{search.strip()}%"
    scope = ""
    params: list = [search.strip(), term, term, term, term, term, term]
    if user and user.get("role_name", "").lower() in {"advocate", "advocate / legal counsel"}:
        scope = " AND EXISTS (SELECT 1 FROM lawyer_case lc WHERE lc.case_id=c.case_id AND lc.lawyer_id=%s)"
        params.append(user.get("lawyer_id") or -1)
    elif user and user.get("role_name", "").lower() in {"court clerk", "court master / bench clerk"}:
        scope = " AND c.court_id=%s"
        params.append(user.get("court_id") or -1)
    elif user and user.get("role_name", "").lower() == "presiding judge":
        scope = " AND (EXISTS (SELECT 1 FROM hearing h JOIN bench_judge bj USING(bench_id) WHERE h.case_id=c.case_id AND bj.judge_id=%s) OR EXISTS (SELECT 1 FROM case_bench_assignment a JOIN bench_judge bj USING(bench_id) WHERE a.case_id=c.case_id AND a.ended_at IS NULL AND bj.judge_id=%s))"
        params.extend([user.get("judge_id") or -1, user.get("judge_id") or -1])
    elif user and user.get("role_name", "").lower() == "public user":
        scope = " AND c.public_access AND NOT c.is_confidential"
    elif user and user.get("role_name", "").lower() == "police & prison liaison":
        scope = " AND c.court_id=%s"
        params.append(user.get("court_id") or -1)
    elif user and user.get("role_name", "").lower() not in {"system administrator", "registry clerk", "filing & scrutiny clerk", "read-only auditor"}:
        scope = " AND FALSE"
    params.extend([limit, offset])
    with get_connection() as conn:
        return conn.execute(f"""SELECT c.case_id,c.cuid,c.cnr,c.case_title,c.case_type,c.filing_date,
                c.court_id,co.jurisdiction_area AS court_name, s.new_status AS current_status,
                c.is_confidential,c.public_access,c.archived_at,c.jurisdiction_note,c.monetary_valuation
            FROM court_case c JOIN court co USING(court_id)
            LEFT JOIN LATERAL (SELECT new_status FROM case_status_history h WHERE h.case_id=c.case_id
                ORDER BY transition_timestamp DESC LIMIT 1) s ON TRUE
            WHERE c.archived_at IS NULL AND (%s='' OR c.cuid ILIKE %s OR c.cnr ILIKE %s OR c.case_title ILIKE %s
                   OR c.case_type ILIKE %s OR co.jurisdiction_area ILIKE %s OR EXISTS(
                     SELECT 1 FROM case_party cp JOIN party p USING(party_id) WHERE cp.case_id=c.case_id AND p.party_name ILIKE %s))
            {scope}
            ORDER BY c.filing_date DESC,c.case_id DESC LIMIT %s OFFSET %s""", tuple(params)).fetchall()


def get_case(case_id: int, *, user: dict) -> dict | None:
    require_permission(user, "CASE_READ", case_id=case_id)
    with get_connection() as conn:
        row = conn.execute("""SELECT c.case_id,c.cuid,c.cnr,c.case_title,c.case_type,c.filing_date,
                c.court_id,co.jurisdiction_area AS court_name,co.physical_address,c.is_confidential,c.public_access,c.archived_at,c.jurisdiction_note,c.monetary_valuation
            FROM court_case c JOIN court co USING(court_id) WHERE c.case_id=%s""", (case_id,)).fetchone()
        if row:
            row["status_history"] = conn.execute("SELECT transition_timestamp,previous_status,new_status,transition_remarks FROM case_status_history WHERE case_id=%s ORDER BY transition_timestamp DESC", (case_id,)).fetchall()
            row["filings"] = conn.execute("SELECT petition_id,subject,verification_status,filing_status,submitted_at,filing_remarks FROM petition WHERE case_id=%s ORDER BY submitted_at DESC", (case_id,)).fetchall()
            row["hearings"] = conn.execute("SELECT hearing_id,hearing_date,hearing_purpose,start_time,end_time,outcome,next_scheduled_hearing_date FROM hearing WHERE case_id=%s ORDER BY hearing_date DESC", (case_id,)).fetchall()
            row["parties"] = conn.execute("SELECT p.party_name,p.party_type,p.phone FROM case_party cp JOIN party p USING(party_id) WHERE cp.case_id=%s ORDER BY p.party_name",(case_id,)).fetchall()
            row["lawyers"] = conn.execute("SELECT l.full_name,l.bar_registration_number,l.phone FROM lawyer_case lc JOIN lawyer l USING(lawyer_id) WHERE lc.case_id=%s ORDER BY l.full_name",(case_id,)).fetchall()
            if has_permission(user, "DOCUMENT_PRIVATE_READ", case_id=case_id):
                document_filter = ""
            else:
                document_filter = " AND is_public"
            row["documents"] = conn.execute(f"SELECT document_id,title,document_type,upload_timestamp,verification_status,confidentiality_level,is_public FROM document WHERE case_id=%s{document_filter} ORDER BY upload_timestamp DESC", (case_id,)).fetchall()
            order_filter="" if (has_permission(user,"ORDER_MANAGE",case_id=case_id) or has_permission(user,"AUDIT_READ")) else " AND is_public"
            row["orders"] = conn.execute(f"SELECT order_id,order_type,order_content,digital_signature_hash,is_public FROM court_order WHERE case_id=%s{order_filter} ORDER BY order_id DESC",(case_id,)).fetchall()
            row["judgments"] = conn.execute(f"SELECT judgment_id,pronouncement_date,verdict_text,digital_signature_hash,is_public FROM judgment WHERE case_id=%s{order_filter} ORDER BY pronouncement_date DESC",(case_id,)).fetchall()
            row["evidence"] = conn.execute("SELECT evidence_id,exhibit_number,submission_date,description,judicial_admission_status,party_id FROM evidence WHERE case_id=%s ORDER BY submission_date DESC",(case_id,)).fetchall()
            row["adjournments"] = conn.execute("SELECT a.adjournment_id,a.reason,a.request_date,a.judicial_approval_status,a.revised_hearing_date,a.request_status,a.review_remarks FROM adjournment a JOIN hearing h USING(hearing_id) WHERE h.case_id=%s ORDER BY a.request_date DESC",(case_id,)).fetchall()
            row["transfers"] = conn.execute("SELECT transfer_id,from_court_id,to_court_id,transferred_at,reason FROM case_transfer_history WHERE case_id=%s ORDER BY transferred_at DESC",(case_id,)).fetchall()
            row["attendance"] = conn.execute("SELECT ha.hearing_id,ha.party_id,ha.lawyer_id,ha.attendance_status,ha.recorded_at FROM hearing_attendance ha JOIN hearing h USING(hearing_id) WHERE h.case_id=%s ORDER BY ha.recorded_at DESC",(case_id,)).fetchall()
            if has_permission(user,"AUDIT_READ",case_id=case_id):
                row["audit"] = conn.execute("SELECT action_performed,\"timestamp\",event_type,entity_name,entity_id,post_modification_state FROM audit_log WHERE case_id=%s ORDER BY \"timestamp\" DESC",(case_id,)).fetchall()
            else:
                row["audit"] = []
        return row


def get_courts() -> list[dict]:
    with get_connection() as conn:
        return conn.execute("SELECT court_id,jurisdiction_area,physical_address FROM court ORDER BY jurisdiction_area,court_id").fetchall()


def get_case_types() -> list[str]:
    with get_connection() as conn:
        return [row["case_type"] for row in conn.execute("SELECT DISTINCT case_type FROM court_case ORDER BY case_type").fetchall()]


def create_case(*, case_title: str, case_type: str,
                filing_date: date, court_id: int, user_id: int) -> int:
    """Insert and audit atomically; CUID/CNR are generated from the identity key."""
    require_permission({"user_id": user_id, **_account_for_user(user_id)}, "CASE_CREATE")
    with get_connection() as conn:
        row = conn.execute("""WITH new_id AS (
                SELECT nextval(pg_get_serial_sequence('court_case','case_id'))::INTEGER AS id
            ) INSERT INTO court_case(case_id,cuid,cnr,case_title,case_type,filing_date,court_id)
            SELECT id,'CUID-'||%s||'-'||lpad(id::text,8,'0'),
                'CNR/'||%s||'/'||%s||'/'||lpad(id::text,8,'0'),%s,%s,%s,%s FROM new_id
            RETURNING case_id""",
            (filing_date.year,court_id,filing_date.year,case_title.strip(),case_type,filing_date,court_id)).fetchone()
        case_id = row["case_id"]
        generated_cuid = f"CUID-{filing_date.year}-{case_id:08d}"
        generated_cnr = f"CNR/{court_id}/{filing_date.year}/{case_id:08d}"
        conn.execute("INSERT INTO case_status_history(case_id,transition_timestamp,previous_status,new_status,transition_remarks,user_id) VALUES (%s,CURRENT_TIMESTAMP,NULL,'Filed','Case registered',%s)", (case_id,user_id))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES ('CASE_REGISTERED',%s,%s,'CREATE','court_case',%s,%s)", (user_id,case_id,case_id,f'{generated_cuid} | {generated_cnr} | {case_title.strip()}'))
        return case_id


def update_case(case_id: int, *, case_title: str, case_type: str, filing_date: date,
                court_id: int, user_id: int) -> int:
    require_permission({"user_id": user_id, **_account_for_user(user_id)}, "CASE_UPDATE", case_id=case_id)
    with get_connection() as conn:
        before = conn.execute("SELECT case_title,case_type,filing_date,court_id FROM court_case WHERE case_id=%s AND archived_at IS NULL FOR UPDATE", (case_id,)).fetchone()
        if not before:
            return 0
        result = conn.execute("UPDATE court_case SET case_title=%s,case_type=%s,filing_date=%s,court_id=%s WHERE case_id=%s",
            (case_title.strip(),case_type,filing_date,court_id,case_id))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,pre_modification_state,post_modification_state) VALUES ('CASE_UPDATED',%s,%s,'UPDATE','court_case',%s,%s,%s)",
            (user_id,case_id,case_id,str(dict(before)),f'{case_title.strip()} | {case_type} | {filing_date} | {court_id}'))
        return result.rowcount


def archive_case(case_id: int, *, reason: str, user_id: int) -> int:
    require_permission({"user_id": user_id, **_account_for_user(user_id)}, "CASE_ARCHIVE", case_id=case_id)
    with get_connection() as conn:
        current=conn.execute("SELECT archived_at FROM court_case WHERE case_id=%s FOR UPDATE",(case_id,)).fetchone()
        latest=conn.execute("SELECT new_status FROM case_status_history WHERE case_id=%s ORDER BY transition_timestamp DESC LIMIT 1",(case_id,)).fetchone()
        previous=latest["new_status"] if latest else None
        if not current or current["archived_at"] is not None:
            return 0
        if previous not in {"Closed","Disposed"}:
            raise ValueError("Only closed or disposed cases can be archived.")
        result = conn.execute("UPDATE court_case SET archived_at=CURRENT_TIMESTAMP,archive_reason=%s WHERE case_id=%s AND archived_at IS NULL", (reason.strip(),case_id))
        if result.rowcount:
            conn.execute("INSERT INTO case_status_history(case_id,transition_timestamp,previous_status,new_status,transition_remarks,user_id) VALUES (%s,CURRENT_TIMESTAMP,%s,'Archived',%s,%s)", (case_id,previous,reason.strip(),user_id))
            conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES ('CASE_ARCHIVED',%s,%s,'ARCHIVE','court_case',%s,%s)", (user_id,case_id,case_id,reason.strip()))
        return result.rowcount


def postgres_version() -> str:
    with get_connection() as conn:
        return conn.execute("SELECT version() AS version").fetchone()["version"]


def _account_for_user(user_id: int) -> dict:
    with get_connection() as conn:
        row = conn.execute("""SELECT u.role_id,r.role_name,u.judge_id,u.clerk_id,u.lawyer_id,u.court_id,u.account_status,u.locked_until
            FROM app_user u JOIN role r USING(role_id) WHERE u.user_id=%s""", (user_id,)).fetchone()
        if not row:
            raise PermissionError("The signed-in account is no longer available.")
        if row["account_status"].lower() != "active" or (row["locked_until"] and row["locked_until"] > datetime.now(timezone.utc)):
            raise PermissionError("The account is inactive or temporarily locked. Sign in again after resolving the account status.")
        return row
