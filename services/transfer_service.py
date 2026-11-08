"""Court transfer workflow with future-hearing safety checks."""
from auth.permissions import require_permission
from database.connection import get_connection


def transfer_case(*, user: dict, case_id: int, to_court_id: int, reason: str) -> None:
    require_permission(user,"CASE_TRANSFER",case_id=case_id)
    if not reason.strip():
        raise ValueError("Transfer reason is required.")
    with get_connection() as conn:
        case=conn.execute("SELECT court_id,archived_at FROM court_case WHERE case_id=%s FOR UPDATE",(case_id,)).fetchone()
        if not case or case["archived_at"] is not None:
            raise ValueError("Only an active case can be transferred.")
        if case["court_id"]==to_court_id:
            raise ValueError("The destination court must differ from the current court.")
        if not conn.execute("SELECT EXISTS(SELECT 1 FROM court WHERE court_id=%s) AS ok",(to_court_id,)).fetchone()["ok"]:
            raise ValueError("Destination court not found.")
        future=conn.execute("SELECT EXISTS(SELECT 1 FROM hearing WHERE case_id=%s AND hearing_date>=CURRENT_DATE) AS has_future",(case_id,)).fetchone()["has_future"]
        if future:
            raise ValueError("Reschedule or conclude upcoming hearings before transferring this case.")
        conn.execute("INSERT INTO case_transfer_history(case_id,from_court_id,to_court_id,transferred_by_user_id,reason) VALUES (%s,%s,%s,%s,%s)",
            (case_id,case["court_id"],to_court_id,user["user_id"],reason.strip()))
        conn.execute("UPDATE court_case SET court_id=%s WHERE case_id=%s",(to_court_id,case_id))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,post_modification_state) VALUES ('CASE_TRANSFERRED',%s,%s,'TRANSFER','court_case',%s)",(user["user_id"],case_id,f'{case["court_id"]} -> {to_court_id}: {reason.strip()}'))
