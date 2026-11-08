"""Bench allocation, conflict-checked hearing scheduling, and proceedings."""
from datetime import date, time

from auth.permissions import require_active_case, require_permission
from database.connection import get_connection


def list_benches() -> list[dict]:
    with get_connection() as conn:
        return conn.execute("SELECT bench_id,bench_name,bench_type FROM bench ORDER BY bench_name").fetchall()


def assign_case_to_bench(*, user: dict, case_id: int, bench_id: int, notes: str = "") -> None:
    require_permission(user,"BENCH_ASSIGN",case_id=case_id)
    require_active_case(case_id)
    with get_connection() as conn:
        active_case=conn.execute("SELECT archived_at FROM court_case WHERE case_id=%s FOR UPDATE",(case_id,)).fetchone()
        if not active_case or active_case["archived_at"] is not None:
            raise ValueError("Only an active case can be assigned to a bench.")
        if not conn.execute("SELECT EXISTS(SELECT 1 FROM bench_judge WHERE bench_id=%s) AS ok",(bench_id,)).fetchone()["ok"]:
            raise ValueError("Assign at least one judge to the bench before allocating cases.")
        conn.execute("SELECT pg_advisory_xact_lock(%s,%s)",(case_id,bench_id))
        conn.execute("UPDATE case_bench_assignment SET ended_at=CURRENT_TIMESTAMP WHERE case_id=%s AND ended_at IS NULL",(case_id,))
        conn.execute("INSERT INTO case_bench_assignment(case_id,bench_id,assigned_by_user_id,assignment_notes) VALUES (%s,%s,%s,%s)",(case_id,bench_id,user["user_id"],notes.strip() or None))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,post_modification_state) VALUES ('CASE_BENCH_ASSIGNED',%s,%s,'ASSIGN','case_bench_assignment',%s)",(user["user_id"],case_id,str(bench_id)))


def schedule_hearing(*, user: dict, case_id: int, hearing_date: date, start_time: time, end_time: time,
                     room_id: int, bench_id: int, purpose: str, session_name: str = "Morning") -> int:
    require_permission(user,"HEARING_MANAGE",case_id=case_id)
    if hearing_date < date.today() or start_time is None or end_time is None or end_time <= start_time or not purpose.strip():
        raise ValueError("Choose a future/current date, valid time range, and hearing purpose.")
    require_active_case(case_id)
    with get_connection() as conn:
        # Serialize schedule checks for the courtroom/day and prevent concurrent double booking.
        conn.execute("SELECT pg_advisory_xact_lock(hashtext(%s),%s)",(str(hearing_date),room_id))
        case = conn.execute("SELECT court_id FROM court_case WHERE case_id=%s AND archived_at IS NULL",(case_id,)).fetchone()
        room = conn.execute("SELECT court_id FROM courtroom WHERE room_id=%s",(room_id,)).fetchone()
        if not case or not room or case["court_id"] != room["court_id"]:
            raise ValueError("The room must belong to the selected case's court.")
        active_assignment=conn.execute("SELECT bench_id FROM case_bench_assignment WHERE case_id=%s AND ended_at IS NULL",(case_id,)).fetchone()
        assigned = bool(active_assignment and active_assignment["bench_id"]==bench_id) or conn.execute(
            "SELECT EXISTS(SELECT 1 FROM hearing WHERE case_id=%s AND bench_id=%s) AS ok",(case_id,bench_id)).fetchone()["ok"]
        if active_assignment and active_assignment["bench_id"]!=bench_id:
            assigned=False
        if not assigned:
            raise ValueError("Assign this case to the selected bench before scheduling its hearing.")
        if conn.execute("SELECT EXISTS(SELECT 1 FROM court_holiday WHERE court_id=%s AND holiday_date=%s OR court_id IS NULL AND holiday_date=%s) AS closed",
                        (case["court_id"],hearing_date,hearing_date)).fetchone()["closed"]:
            raise ValueError("The court is marked closed on this date.")
        overlap = conn.execute("""SELECT EXISTS(SELECT 1 FROM hearing h WHERE h.hearing_date=%s AND h.room_id=%s
            AND h.start_time < %s AND h.end_time > %s) AS conflict""",
            (hearing_date,room_id,end_time,start_time)).fetchone()["conflict"]
        if overlap:
            raise ValueError("That courtroom already has an overlapping hearing.")
        judge_ids = conn.execute("SELECT judge_id FROM bench_judge WHERE bench_id=%s ORDER BY judge_id",(bench_id,)).fetchall()
        if not judge_ids:
            raise ValueError("The selected bench has no assigned judges.")
        for judge in judge_ids:
            conn.execute("SELECT pg_advisory_xact_lock(hashtext(%s),%s)",(str(hearing_date),judge["judge_id"]))
        judge_overlap = conn.execute("""SELECT EXISTS(
            SELECT 1 FROM hearing h JOIN bench_judge old_bj ON old_bj.bench_id=h.bench_id
            JOIN bench_judge new_bj ON new_bj.judge_id=old_bj.judge_id
            WHERE h.hearing_date=%s AND new_bj.bench_id=%s AND h.start_time < %s AND h.end_time > %s
        ) AS conflict""",(hearing_date,bench_id,end_time,start_time)).fetchone()["conflict"]
        if judge_overlap:
            raise ValueError("A judge assigned to this bench has an overlapping hearing.")
        cause = conn.execute("""SELECT cause_list_id FROM cause_list WHERE cause_date=%s AND court_id=%s AND session_name=%s
            ORDER BY cause_list_id LIMIT 1 FOR UPDATE""",(hearing_date,case["court_id"],session_name.strip())).fetchone()
        if cause:
            cause_list_id = cause["cause_list_id"]
        else:
            cause_list_id = conn.execute("""INSERT INTO cause_list(cause_date,court_id,session_name,publication_status,created_by_user_id)
                VALUES (%s,%s,%s,'DRAFT',%s) ON CONFLICT(court_id,cause_date,session_name) DO UPDATE SET session_name=EXCLUDED.session_name
                RETURNING cause_list_id""",(hearing_date,case["court_id"],session_name.strip(),user["user_id"])).fetchone()["cause_list_id"]
        sequence = conn.execute("SELECT COALESCE(MAX(sequence_number),0)+1 AS next_seq FROM hearing WHERE cause_list_id=%s",(cause_list_id,)).fetchone()["next_seq"]
        hearing = conn.execute("""INSERT INTO hearing(hearing_date,hearing_purpose,start_time,end_time,case_id,room_id,bench_id,cause_list_id,sequence_number)
            VALUES (%s,%s,%s,%s,%s,%s,%s,%s,%s) RETURNING hearing_id""",
            (hearing_date,purpose.strip(),start_time,end_time,case_id,room_id,bench_id,cause_list_id,sequence)).fetchone()
        counsel = conn.execute("""SELECT DISTINCT u.user_id,u.email FROM lawyer_case lc JOIN app_user u USING(lawyer_id)
            WHERE lc.case_id=%s AND lc.representation_end_date IS NULL AND u.account_status='Active'""",(case_id,)).fetchall()
        for contact in counsel:
            email=contact["email"] if contact["email"] and "@" in contact["email"] else ""
            conn.execute("""INSERT INTO notification(message,recipient,status,case_id,user_id,channel,attempt_count)
                VALUES (%s,%s,%s,%s,%s,'EMAIL',0)""",
                (f"A hearing is scheduled on {hearing_date} at {start_time} for case {case_id}.",email,'QUEUED' if email else 'NO_ADDRESS',case_id,contact["user_id"]))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES ('HEARING_SCHEDULED',%s,%s,'CREATE','hearing',%s,%s)",(user["user_id"],case_id,hearing["hearing_id"],f'{hearing_date} {start_time}-{end_time}'))
        return hearing["hearing_id"]


def record_proceedings(*, user: dict, hearing_id: int, summary: str, outcome: str,
                       next_date: date | None = None, attendance: list[dict] | None = None) -> None:
    with get_connection() as conn:
        hearing = conn.execute("SELECT case_id FROM hearing WHERE hearing_id=%s FOR UPDATE",(hearing_id,)).fetchone()
        if not hearing:
            raise ValueError("Hearing not found.")
        require_permission(user,"PROCEEDING_RECORD",case_id=hearing["case_id"])
        require_active_case(hearing["case_id"])
        if not summary.strip() or not outcome.strip():
            raise ValueError("Proceedings summary and outcome are required.")
        conn.execute("UPDATE hearing SET proceeding_summary=%s,outcome=%s,next_scheduled_hearing_date=%s WHERE hearing_id=%s",
            (summary.strip(),outcome.strip(),next_date,hearing_id))
        for attendee in attendance or []:
            party_id,lawyer_id=attendee.get("party_id"),attendee.get("lawyer_id")
            if (party_id is None)==(lawyer_id is None):
                raise ValueError("Attendance must reference exactly one party or lawyer.")
            link_sql="SELECT EXISTS(SELECT 1 FROM case_party WHERE case_id=%s AND party_id=%s) AS ok" if party_id else "SELECT EXISTS(SELECT 1 FROM lawyer_case WHERE case_id=%s AND lawyer_id=%s) AS ok"
            identity=party_id if party_id else lawyer_id
            if not conn.execute(link_sql,(hearing["case_id"],identity)).fetchone()["ok"]:
                raise ValueError("The attendee is not linked to this case.")
            if party_id:
                conn.execute("""INSERT INTO hearing_attendance(hearing_id,party_id,attendance_status,recorded_by_user_id,notes)
                    VALUES (%s,%s,%s,%s,%s) ON CONFLICT (hearing_id,party_id) WHERE party_id IS NOT NULL
                    DO UPDATE SET attendance_status=EXCLUDED.attendance_status,recorded_by_user_id=EXCLUDED.recorded_by_user_id,recorded_at=CURRENT_TIMESTAMP,notes=EXCLUDED.notes""",
                    (hearing_id,party_id,attendee["status"],user["user_id"],attendee.get("notes")))
            else:
                conn.execute("""INSERT INTO hearing_attendance(hearing_id,lawyer_id,attendance_status,recorded_by_user_id,notes)
                    VALUES (%s,%s,%s,%s,%s) ON CONFLICT (hearing_id,lawyer_id) WHERE lawyer_id IS NOT NULL
                    DO UPDATE SET attendance_status=EXCLUDED.attendance_status,recorded_by_user_id=EXCLUDED.recorded_by_user_id,recorded_at=CURRENT_TIMESTAMP,notes=EXCLUDED.notes""",
                    (hearing_id,lawyer_id,attendee["status"],user["user_id"],attendee.get("notes")))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES ('PROCEEDINGS_RECORDED',%s,%s,'UPDATE','hearing',%s,%s)",(user["user_id"],hearing["case_id"],hearing_id,outcome.strip()))


def hearings_for_case(case_id: int, *, user: dict) -> list[dict]:
    require_permission(user,"CASE_READ",case_id=case_id)
    with get_connection() as conn:
        return conn.execute("""SELECT h.hearing_id,h.hearing_date,h.hearing_purpose,h.start_time,h.end_time,h.proceeding_summary,h.outcome,h.next_scheduled_hearing_date,
            h.room_id,cr.room_number,h.bench_id,b.bench_name,h.cause_list_id,h.sequence_number FROM hearing h
            JOIN courtroom cr USING(room_id) JOIN bench b USING(bench_id) WHERE h.case_id=%s ORDER BY h.hearing_date DESC,h.start_time""",(case_id,)).fetchall()
