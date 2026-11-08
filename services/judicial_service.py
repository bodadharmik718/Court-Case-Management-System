"""Judicial order, judgment, adjournment, and cause-list workflows."""
from datetime import date

from auth.permissions import require_active_case, require_permission
from database.connection import get_connection


def create_order(*, user: dict, case_id: int, hearing_id: int, order_type: str, content: str) -> int:
    require_permission(user,"ORDER_MANAGE",case_id=case_id)
    require_active_case(case_id)
    if not user.get("judge_id"):
        raise PermissionError("Link this account to a judge profile before creating an order.")
    if not order_type.strip() or not content.strip():
        raise ValueError("Order type and content are required.")
    with get_connection() as conn:
        valid = conn.execute("SELECT EXISTS(SELECT 1 FROM hearing WHERE hearing_id=%s AND case_id=%s) AS ok",(hearing_id,case_id)).fetchone()["ok"]
        if not valid:
            raise ValueError("Select a hearing belonging to the selected case.")
        if not conn.execute("SELECT EXISTS(SELECT 1 FROM hearing h JOIN bench_judge bj USING(bench_id) WHERE h.hearing_id=%s AND bj.judge_id=%s) AS ok",(hearing_id,user["judge_id"])).fetchone()["ok"]:
            raise PermissionError("The judge is not assigned to the hearing bench.")
        row = conn.execute("INSERT INTO court_order(order_type,order_content,case_id,issued_by_judge_id,hearing_id) VALUES (%s,%s,%s,%s,%s) RETURNING order_id",
            (order_type.strip(),content.strip(),case_id,user["judge_id"],hearing_id)).fetchone()
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES ('ORDER_DRAFT_CREATED',%s,%s,'CREATE','court_order',%s,%s)",(user["user_id"],case_id,row["order_id"],order_type.strip()))
        return row["order_id"]


def create_judgment(*, user: dict, case_id: int, pronouncement_date: date, verdict: str) -> int:
    require_permission(user,"ORDER_MANAGE",case_id=case_id)
    require_active_case(case_id)
    if not user.get("judge_id") or not verdict.strip():
        raise ValueError("A judge profile and judgment text are required.")
    with get_connection() as conn:
        row = conn.execute("INSERT INTO judgment(pronouncement_date,verdict_text,case_id) VALUES (%s,%s,%s) RETURNING judgment_id",
            (pronouncement_date,verdict.strip(),case_id)).fetchone()
        conn.execute("INSERT INTO case_status_history(case_id,transition_timestamp,previous_status,new_status,transition_remarks,user_id) VALUES (%s,CURRENT_TIMESTAMP,NULL,'Disposed','Judgment entered',%s)",(case_id,user["user_id"]))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES ('JUDGMENT_CREATED',%s,%s,'CREATE','judgment',%s,%s)",(user["user_id"],case_id,row["judgment_id"],verdict.strip()))
        return row["judgment_id"]


def set_order_public(*, user: dict, order_id: int, publish: bool) -> None:
    with get_connection() as conn:
        row = conn.execute("SELECT case_id FROM court_order WHERE order_id=%s",(order_id,)).fetchone()
        if not row:
            raise ValueError("Order not found.")
        require_permission(user,"CASE_PUBLISH",case_id=row["case_id"])
        require_active_case(row["case_id"])
        if publish and not conn.execute("SELECT digital_signature_hash IS NOT NULL AS signed FROM court_order WHERE order_id=%s",(order_id,)).fetchone()["signed"]:
            raise ValueError("An order must have a verified digital signature before it can be released publicly.")
        conn.execute("UPDATE court_order SET is_public=%s WHERE order_id=%s",(publish,order_id))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES (%s,%s,%s,'PUBLICATION','court_order',%s,%s)",("ORDER_PUBLISHED" if publish else "ORDER_UNPUBLISHED",user["user_id"],row["case_id"],order_id,str(publish)))


def set_judgment_public(*, user: dict, judgment_id: int, publish: bool) -> None:
    with get_connection() as conn:
        row=conn.execute("SELECT case_id,digital_signature_hash FROM judgment WHERE judgment_id=%s",(judgment_id,)).fetchone()
        if not row:
            raise ValueError("Judgment not found.")
        require_permission(user,"CASE_PUBLISH",case_id=row["case_id"])
        require_active_case(row["case_id"])
        if publish and not row["digital_signature_hash"]:
            raise ValueError("A judgment must have a verified digital signature before it can be released publicly.")
        conn.execute("UPDATE judgment SET is_public=%s WHERE judgment_id=%s",(publish,judgment_id))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES (%s,%s,%s,'PUBLICATION','judgment',%s,%s)",("JUDGMENT_PUBLISHED" if publish else "JUDGMENT_UNPUBLISHED",user["user_id"],row["case_id"],judgment_id,str(publish)))


def pending_adjournments(*, user: dict) -> list[dict]:
    if not user.get("judge_id"):
        raise PermissionError("Link this account to a judge profile before reviewing adjournments.")
    with get_connection() as conn:
        return conn.execute("""SELECT a.adjournment_id,a.reason,a.revised_hearing_date,a.party_id,h.case_id,c.cnr,c.case_title
            FROM adjournment a JOIN hearing h USING(hearing_id) JOIN court_case c USING(case_id)
            WHERE a.request_status='PENDING' AND a.reviewed_by_judge_id=%s ORDER BY a.request_date""",(user["judge_id"],)).fetchall()


def request_adjournment(*, user: dict, hearing_id: int, party_id: int, reason: str, revised_date: date) -> int:
    with get_connection() as conn:
        hearing = conn.execute("SELECT case_id FROM hearing WHERE hearing_id=%s",(hearing_id,)).fetchone()
        if not hearing:
            raise ValueError("Hearing not found.")
        require_permission(user,"ADJOURNMENT_REQUEST",case_id=hearing["case_id"])
        require_active_case(hearing["case_id"])
        linked = conn.execute("SELECT EXISTS(SELECT 1 FROM case_party WHERE case_id=%s AND party_id=%s) AS ok",(hearing["case_id"],party_id)).fetchone()["ok"]
        if not linked or not reason.strip() or revised_date <= date.today():
            raise ValueError("Choose a linked party, provide a reason, and request a future date.")
        conn.execute("SELECT pg_advisory_xact_lock(%s,%s)",(hearing["case_id"],party_id))
        count = conn.execute("""SELECT COUNT(*) AS n FROM adjournment a JOIN hearing h USING(hearing_id)
            WHERE h.case_id=%s AND a.party_id=%s AND a.request_status IN ('PENDING','APPROVED')""",
            (hearing["case_id"],party_id)).fetchone()["n"]
        if count >= 3:
            raise ValueError("The SRS limit of three adjournment requests per party has been reached.")
        judge_id = conn.execute("SELECT judge_id FROM bench_judge WHERE bench_id=(SELECT bench_id FROM hearing WHERE hearing_id=%s) ORDER BY judge_id LIMIT 1",(hearing_id,)).fetchone()
        if not judge_id:
            raise ValueError("The hearing bench has no assigned judge to review this request.")
        row = conn.execute("""INSERT INTO adjournment(reason,request_date,judicial_approval_status,revised_hearing_date,hearing_id,reviewed_by_judge_id,party_id,requested_by_user_id,request_status)
            VALUES (%s,CURRENT_DATE,'Pending',%s,%s,%s,%s,%s,'PENDING') RETURNING adjournment_id""",
            (reason.strip(),revised_date,hearing_id,judge_id["judge_id"],party_id,user["user_id"])).fetchone()
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES ('ADJOURNMENT_REQUESTED',%s,%s,'CREATE','adjournment',%s,%s)",(user["user_id"],hearing["case_id"],row["adjournment_id"],reason.strip()))
        return row["adjournment_id"]


def review_adjournment(*, user: dict, adjournment_id: int, approve: bool, remarks: str = "") -> None:
    if not user.get("judge_id"):
        raise PermissionError("Link this account to a judge profile before reviewing adjournments.")
    with get_connection() as conn:
        row = conn.execute("""SELECT a.hearing_id,a.request_status,a.revised_hearing_date,h.case_id,h.room_id,h.bench_id,h.hearing_date,h.start_time,h.end_time,h.cause_list_id
            FROM adjournment a JOIN hearing h USING(hearing_id)
            WHERE a.adjournment_id=%s AND a.reviewed_by_judge_id=%s FOR UPDATE""",(adjournment_id,user["judge_id"])).fetchone()
        if not row or row["request_status"] != "PENDING":
            raise ValueError("Pending adjournment request not found for this judge.")
        require_permission(user,"ORDER_MANAGE",case_id=row["case_id"])
        require_active_case(row["case_id"])
        status = "APPROVED" if approve else "REJECTED"
        if approve:
            revised = row["revised_hearing_date"]
            if not revised or revised <= date.today():
                raise ValueError("The requested replacement date must be in the future.")
            court=conn.execute("SELECT court_id FROM court_case WHERE case_id=%s",(row["case_id"],)).fetchone()
            if conn.execute("SELECT EXISTS(SELECT 1 FROM court_holiday WHERE (court_id=%s OR court_id IS NULL) AND holiday_date=%s) AS closed",(court["court_id"],revised)).fetchone()["closed"]:
                raise ValueError("The court is marked closed on the requested date.")
            conn.execute("SELECT pg_advisory_xact_lock(hashtext(%s),%s)",(str(revised),row["room_id"]))
            conflict = conn.execute("""SELECT EXISTS(SELECT 1 FROM hearing h WHERE h.hearing_id<>%s AND h.hearing_date=%s AND h.room_id=%s
                AND h.start_time < %s AND h.end_time > %s) AS conflict""",
                (row["hearing_id"],revised,row["room_id"],row["end_time"],row["start_time"])).fetchone()["conflict"]
            if conflict:
                raise ValueError("The courtroom has another hearing during the requested time.")
            judges = conn.execute("SELECT judge_id FROM bench_judge WHERE bench_id=%s ORDER BY judge_id",(row["bench_id"],)).fetchall()
            for judge in judges:
                conn.execute("SELECT pg_advisory_xact_lock(hashtext(%s),%s)",(str(revised),judge["judge_id"]))
            judge_conflict = conn.execute("""SELECT EXISTS(SELECT 1 FROM hearing h JOIN bench_judge bj USING(bench_id)
                WHERE h.hearing_id<>%s AND h.hearing_date=%s AND bj.judge_id=ANY(%s)
                AND h.start_time < %s AND h.end_time > %s) AS conflict""",
                (row["hearing_id"],revised,[j["judge_id"] for j in judges],row["end_time"],row["start_time"])).fetchone()["conflict"] if judges else False
            if judge_conflict:
                raise ValueError("A judge assigned to this bench has another hearing during the requested time.")
            cause = conn.execute("""SELECT cause_list_id FROM cause_list WHERE cause_date=%s AND court_id=(SELECT court_id FROM court_case WHERE case_id=%s)
                AND session_name=(SELECT session_name FROM cause_list WHERE cause_list_id=%s) ORDER BY cause_list_id LIMIT 1""",
                (revised,row["case_id"],row["cause_list_id"])).fetchone()
            if cause:
                cause_id = cause["cause_list_id"]
            else:
                old_session=conn.execute("SELECT session_name,court_id FROM cause_list WHERE cause_list_id=%s",(row["cause_list_id"],)).fetchone()
                session=old_session["session_name"] or "Morning"
                cause_id=conn.execute("""INSERT INTO cause_list(cause_date,court_id,session_name,publication_status,created_by_user_id)
                    VALUES (%s,%s,%s,'DRAFT',%s) ON CONFLICT(court_id,cause_date,session_name) DO UPDATE SET session_name=EXCLUDED.session_name
                    RETURNING cause_list_id""",(revised,old_session["court_id"],session,user["user_id"])).fetchone()["cause_list_id"]
            sequence=conn.execute("SELECT COALESCE(MAX(sequence_number),0)+1 AS n FROM hearing WHERE cause_list_id=%s",(cause_id,)).fetchone()["n"]
            conn.execute("UPDATE hearing SET hearing_date=%s,cause_list_id=%s,sequence_number=%s WHERE hearing_id=%s",(revised,cause_id,sequence,row["hearing_id"]))
        conn.execute("UPDATE adjournment SET request_status=%s,judicial_approval_status=%s,reviewed_at=CURRENT_TIMESTAMP,review_remarks=%s WHERE adjournment_id=%s",
            (status,status,remarks.strip() or None,adjournment_id))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES (%s,%s,%s,'REVIEW','adjournment',%s,%s)",(f'ADJOURNMENT_{status}',user["user_id"],row["case_id"],adjournment_id,remarks.strip()))


def publish_cause_list(*, user: dict, cause_list_id: int) -> None:
    require_permission(user,"HEARING_MANAGE")
    with get_connection() as conn:
        row = conn.execute("SELECT cause_date,court_id FROM cause_list WHERE cause_list_id=%s FOR UPDATE",(cause_list_id,)).fetchone()
        if not row:
            raise ValueError("Cause list not found.")
        case_rows = conn.execute("SELECT DISTINCT case_id FROM hearing WHERE cause_list_id=%s",(cause_list_id,)).fetchall()
        if not case_rows:
            raise ValueError("An empty cause list cannot be published.")
        for case in case_rows:
            require_permission(user,"HEARING_MANAGE",case_id=case["case_id"])
            require_active_case(case["case_id"])
        conn.execute("UPDATE cause_list SET publication_status='PUBLISHED' WHERE cause_list_id=%s",(cause_list_id,))


def public_cause_lists(day: date | None = None) -> list[dict]:
    with get_connection() as conn:
        return conn.execute("""SELECT cl.cause_date,cl.session_name,c.cnr,c.case_title,h.hearing_purpose,h.start_time,h.end_time,
            cr.room_number,b.bench_name,h.sequence_number FROM cause_list cl JOIN hearing h USING(cause_list_id)
            JOIN court_case c USING(case_id) JOIN courtroom cr USING(room_id) JOIN bench b USING(bench_id)
            WHERE cl.publication_status='PUBLISHED' AND c.public_access=TRUE AND c.is_confidential=FALSE
              AND c.archived_at IS NULL AND (%s::date IS NULL OR cl.cause_date=%s)
            ORDER BY cl.cause_date,cl.session_name,h.sequence_number""",(day,day)).fetchall()
