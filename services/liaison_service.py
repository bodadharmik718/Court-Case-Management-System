"""Audited, role-restricted police/prison service status tracking."""
from auth.permissions import require_permission
from database.connection import get_connection


def record_liaison_update(*, user: dict, case_id: int, event_type: str, status: str,
                          notes: str = "", witness_id: int | None = None) -> int:
    require_permission(user,"POLICE_LIAISON",case_id=case_id)
    event_type = event_type.upper()
    permitted = {"SUMMONS_DISPATCHED","SERVICE_COMPLETED","BAIL_RELEASE_UPDATED","WARRANT_STATUS"}
    if event_type not in permitted or not status.strip():
        raise ValueError("Select a valid liaison event and enter its status.")
    with get_connection() as conn:
        if witness_id is not None and not conn.execute("SELECT EXISTS(SELECT 1 FROM case_witness WHERE case_id=%s AND witness_id=%s) AS ok",(case_id,witness_id)).fetchone()["ok"]:
            raise ValueError("The witness is not associated with this case.")
        row = conn.execute("""INSERT INTO agency_liaison_event(case_id,witness_id,event_type,event_status,event_notes,recorded_by_user_id)
            VALUES (%s,%s,%s,%s,%s,%s) RETURNING liaison_event_id""",
            (case_id,witness_id,event_type,status.strip(),notes.strip() or None,user["user_id"])).fetchone()
        if witness_id is not None and event_type in {"SUMMONS_DISPATCHED","SERVICE_COMPLETED"}:
            conn.execute("UPDATE case_witness SET summons_status=%s WHERE case_id=%s AND witness_id=%s",(status.strip(),case_id,witness_id))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES ('AGENCY_LIAISON_UPDATED',%s,%s,'LIAISON','agency_liaison_event',%s,%s)",(user["user_id"],case_id,row["liaison_event_id"],event_type+': '+status.strip()))
        return row["liaison_event_id"]


def liaison_history(*, user: dict, case_id: int) -> list[dict]:
    require_permission(user,"POLICE_LIAISON",case_id=case_id)
    with get_connection() as conn:
        return conn.execute("SELECT liaison_event_id,event_type,event_status,event_notes,recorded_at,witness_id FROM agency_liaison_event WHERE case_id=%s ORDER BY recorded_at DESC",(case_id,)).fetchall()
