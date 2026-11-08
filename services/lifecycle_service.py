"""Allowed case lifecycle transitions, recorded as append-only history."""
from auth.permissions import require_permission
from database.connection import get_connection


TRANSITIONS={
    "Filed":{"Under Review","Closed"},
    "Under Review":{"Evidence Review","Under Hearing","Closed"},
    "Evidence Review":{"Under Hearing","Under Review","Closed"},
    "Under Hearing":{"Under Review","Evidence Review","Disposed","Closed"},
    "Closed":{"Disposed"},
    "Disposed":set(),
    "Archived":set(),
}


def transition_case(*, user: dict, case_id: int, new_status: str, remarks: str) -> str:
    require_permission(user,"CASE_STATUS_MANAGE",case_id=case_id)
    if not remarks.strip() or new_status not in TRANSITIONS:
        raise ValueError("Choose a valid status and enter transition remarks.")
    with get_connection() as conn:
        case=conn.execute("SELECT archived_at FROM court_case WHERE case_id=%s FOR UPDATE",(case_id,)).fetchone()
        if not case or case["archived_at"] is not None:
            raise ValueError("Case not found or archived.")
        latest=conn.execute("SELECT new_status FROM case_status_history WHERE case_id=%s ORDER BY transition_timestamp DESC LIMIT 1",(case_id,)).fetchone()
        previous=latest["new_status"] if latest else None
        if previous==new_status:
            raise ValueError("The case already has that status.")
        if previous and new_status not in TRANSITIONS.get(previous,set()):
            raise ValueError(f"Transition from {previous} to {new_status} is not allowed.")
        if new_status=="Disposed" and not conn.execute("SELECT EXISTS(SELECT 1 FROM judgment WHERE case_id=%s) AS has_judgment",(case_id,)).fetchone()["has_judgment"]:
            raise ValueError("A case must have a judgment before it can be marked disposed.")
        conn.execute("INSERT INTO case_status_history(case_id,transition_timestamp,previous_status,new_status,transition_remarks,user_id) VALUES (%s,CURRENT_TIMESTAMP,%s,%s,%s,%s)",
            (case_id,previous,new_status,remarks.strip(),user["user_id"]))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,post_modification_state) VALUES ('CASE_STATUS_CHANGED',%s,%s,'LIFECYCLE','court_case',%s)",(user["user_id"],case_id,f'{previous or "None"} -> {new_status}: {remarks.strip()}'))
        return previous or "New"
