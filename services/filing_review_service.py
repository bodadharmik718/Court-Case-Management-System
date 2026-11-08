"""Registry scrutiny and seven-calendar-day defect workflow."""
from datetime import date, timedelta

from auth.permissions import require_active_case, require_permission
from database.connection import get_connection


def pending_filings(*, user: dict) -> list[dict]:
    require_permission(user, "FILING_REVIEW")
    with get_connection() as conn:
        return conn.execute("""SELECT p.petition_id,p.subject,p.filing_status,p.submitted_at,p.filing_remarks,
                    c.case_id,c.cuid,c.cnr,c.case_title,l.full_name AS lawyer_name
            FROM petition p JOIN court_case c USING(case_id) JOIN lawyer l USING(lawyer_id)
            WHERE p.filing_status IN ('PENDING_SCRUTINY','RETURNED_FOR_CORRECTION') AND c.archived_at IS NULL
            ORDER BY p.submitted_at,p.petition_id""").fetchall()


def record_scrutiny(*, user: dict, petition_id: int, decision: str, remarks: str,
                    defect_description: str = "") -> int | None:
    require_permission(user, "FILING_REVIEW")
    decision = decision.upper()
    if decision not in {"APPROVE", "DEFECT"}:
        raise ValueError("Choose approve or return with defect.")
    if not remarks.strip() or (decision == "DEFECT" and not defect_description.strip()):
        raise ValueError("Add scrutiny remarks and describe the defect when returning a filing.")
    if not user.get("clerk_id"):
        raise PermissionError("Link this account to a court clerk profile before reviewing filings.")
    with get_connection() as conn:
        filing = conn.execute("""SELECT p.case_id,p.lawyer_id,p.submitted_by_user_id,p.subject,p.filing_status
            FROM petition p WHERE p.petition_id=%s FOR UPDATE""",(petition_id,)).fetchone()
        if not filing or filing["filing_status"] not in {"PENDING_SCRUTINY","RETURNED_FOR_CORRECTION"}:
            raise ValueError("This filing is unavailable or no longer awaiting scrutiny.")
        case_id = filing["case_id"]
        require_active_case(case_id)
        if decision == "APPROVE":
            status = "APPROVED"
            conn.execute("""UPDATE petition SET filing_status=%s,verification_status='Verified',filing_remarks=%s,
                scrutinized_by_clerk_id=%s,verified_by_clerk_id=%s WHERE petition_id=%s""",
                (status,remarks.strip(),user["clerk_id"],user["clerk_id"],petition_id))
            conn.execute("INSERT INTO case_status_history(case_id,transition_timestamp,previous_status,new_status,transition_remarks,user_id) VALUES (%s,CURRENT_TIMESTAMP,'Filed','Under Review',%s,%s)",(case_id,remarks.strip(),user["user_id"]))
            defect_id = None
        else:
            status = "RETURNED_FOR_CORRECTION"
            conn.execute("UPDATE petition SET filing_status=%s,verification_status='Returned for Correction',filing_remarks=%s,scrutinized_by_clerk_id=%s WHERE petition_id=%s",
                (status,remarks.strip(),user["clerk_id"],petition_id))
            deadline = date.today() + timedelta(days=7)
            defect = conn.execute("""INSERT INTO filing_defect(defect_description,cure_deadline,cure_status,identification_date,clerk_id,case_id,updated_at)
                VALUES (%s,%s,'Pending',CURRENT_DATE,%s,%s,CURRENT_TIMESTAMP) RETURNING defect_id""",
                (defect_description.strip(),deadline,user["clerk_id"],case_id)).fetchone()
            defect_id = defect["defect_id"]
            target_user = filing["submitted_by_user_id"]
            if target_user:
                recipient = conn.execute("SELECT email FROM app_user WHERE user_id=%s",(target_user,)).fetchone()
                email = recipient["email"] if recipient and recipient["email"] and "@" in recipient["email"] else ""
                conn.execute("""INSERT INTO notification(message,recipient,status,case_id,user_id,channel,attempt_count)
                    VALUES (%s,%s,%s,%s,%s,'EMAIL',0)""",
                    (f"Filing {filing['subject']} returned for correction. Cure deadline: {deadline}.",email,'QUEUED' if email else 'NO_ADDRESS',case_id,target_user))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES (%s,%s,%s,'SCRUTINY','petition',%s,%s)",
            (f"FILING_{status}",user["user_id"],case_id,petition_id,remarks.strip()))
        return defect_id


def resolve_defect(*, user: dict, defect_id: int, remarks: str) -> None:
    require_permission(user, "DEFECT_MANAGE")
    if not user.get("clerk_id"):
        raise PermissionError("Link this account to a court clerk profile before resolving defects.")
    if not remarks.strip():
        raise ValueError("Resolution notes are required.")
    with get_connection() as conn:
        defect = conn.execute("SELECT case_id FROM filing_defect WHERE defect_id=%s AND lower(cure_status) NOT IN ('cured','resolved') FOR UPDATE",(defect_id,)).fetchone()
        if not defect:
            raise ValueError("Open defect not found.")
        require_active_case(defect["case_id"])
        conn.execute("UPDATE filing_defect SET cure_status='Cured',resolved_by_clerk_id=%s,resolution_remarks=%s,updated_at=CURRENT_TIMESTAMP WHERE defect_id=%s",
            (user["clerk_id"],remarks.strip(),defect_id))
        conn.execute("UPDATE petition SET filing_status='PENDING_SCRUTINY',verification_status='Pending',filing_remarks=%s WHERE case_id=%s AND filing_status='RETURNED_FOR_CORRECTION'",
            (remarks.strip(),defect["case_id"]))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES ('FILING_DEFECT_CURED',%s,%s,'UPDATE','filing_defect',%s,%s)",(user["user_id"],defect["case_id"],defect_id,remarks.strip()))
