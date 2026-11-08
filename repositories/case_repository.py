from datetime import date

from database.connection import get_connection


def list_cases(search: str = "", limit: int = 100, offset: int = 0) -> list[dict]:
    term = f"%{search.strip()}%"
    with get_connection() as conn:
        return conn.execute(
            """SELECT DISTINCT vcs.*, c.is_confidential
               FROM v_case_current_status vcs JOIN case_file c USING(case_id)
               LEFT JOIN case_party cp ON cp.case_id = c.case_id
               LEFT JOIN party p ON p.party_id = cp.party_id
               LEFT JOIN person per ON per.person_id = p.person_id
               LEFT JOIN organization org ON org.organization_id = p.organization_id
               WHERE (%s = '' OR COALESCE(vcs.cnr,'') ILIKE %s OR vcs.case_title ILIKE %s
                 OR COALESCE(per.full_name,'') ILIKE %s OR COALESCE(org.organization_name,'') ILIKE %s)
               ORDER BY vcs.filing_date DESC, vcs.case_id DESC LIMIT %s OFFSET %s""",
            (search.strip(), term, term, term, term, limit, offset),
        ).fetchall()


def case_details(case_id: int) -> dict | None:
    with get_connection() as conn:
        case = conn.execute("""SELECT vcs.*, c.subject_summary, c.court_value, c.language_code, c.is_confidential
            FROM v_case_current_status vcs JOIN case_file c USING(case_id)
            WHERE vcs.case_id = %s""", (case_id,)).fetchone()
        if not case:
            return None
        queries = {
            "parties": """SELECT cp.case_party_id, COALESCE(per.full_name, org.organization_name) party_name,
                        cpr.role_name, cp.is_primary, cp.joined_on, cp.ceased_on
                 FROM case_party cp JOIN party p USING(party_id) JOIN case_party_role cpr USING(party_role_code)
                 LEFT JOIN person per USING(person_id) LEFT JOIN organization org USING(organization_id)
                 WHERE cp.case_id=%s ORDER BY cp.is_primary DESC, party_name""",
            "lawyers": """SELECT per.full_name lawyer_name, lr.appointed_on, lr.ended_on,
                        lr.representation_status, cpr.role_name
                 FROM lawyer_representation lr JOIN lawyer_profile lp USING(lawyer_id)
                 JOIN person per USING(person_id) JOIN case_party cp USING(case_party_id)
                 JOIN case_party_role cpr USING(party_role_code) WHERE cp.case_id=%s ORDER BY lr.appointed_on DESC""",
            "hearings": """SELECT hearing_id, hearing_date, start_time, end_time, hearing_purpose, hearing_status,
                        b.bench_name, cr.room_code FROM hearing h LEFT JOIN bench b USING(bench_id)
                 LEFT JOIN courtroom cr USING(courtroom_id) WHERE case_id=%s ORDER BY hearing_date DESC""",
            "filings": "SELECT filing_id, filing_number, title, filing_type_code, filing_status_code, submitted_at FROM case_filing WHERE case_id=%s ORDER BY submitted_at DESC",
            "evidence": "SELECT evidence_id, evidence_title, evidence_type_code, exhibit_number, admission_status, confidentiality_level FROM evidence_item WHERE case_id=%s ORDER BY submission_date DESC",
            "orders": "SELECT order_id, order_date, order_title, order_type_code, order_status FROM court_order WHERE case_id=%s ORDER BY order_date DESC",
            "documents": "SELECT document_id, title, document_type_code, confidentiality_level, public_visible FROM document WHERE case_id=%s AND is_active ORDER BY created_at DESC",
            "status_history": "SELECT h.changed_at, s.status_name, h.remarks, u.username FROM case_status_history h JOIN case_status s USING(status_code) LEFT JOIN user_account u ON u.user_id=h.changed_by_user_id WHERE h.case_id=%s ORDER BY h.changed_at DESC, h.case_status_history_id DESC",
            "transfers": "SELECT ct.transfer_date, src.forum_name from_forum, dst.forum_name to_forum, ct.transfer_reason, ct.order_reference FROM case_transfer ct JOIN forum src ON src.forum_id=ct.from_forum_id JOIN forum dst ON dst.forum_id=ct.to_forum_id WHERE ct.case_id=%s ORDER BY ct.transfer_date DESC",
        }
        result = {"case": case}
        for name, sql in queries.items():
            result[name] = conn.execute(sql, (case_id,)).fetchall()
        return result


def lookups() -> dict:
    with get_connection() as conn:
        return {
            "forums": conn.execute("SELECT forum_id, forum_name FROM forum WHERE is_active ORDER BY forum_name").fetchall(),
            "types": conn.execute("SELECT case_type_id, case_type_name FROM case_type WHERE is_active ORDER BY case_type_name").fetchall(),
            "statuses": conn.execute("SELECT status_code, status_name FROM case_status ORDER BY status_name").fetchall(),
            "document_types": conn.execute("SELECT document_type_code, document_type_name FROM document_type ORDER BY document_type_name").fetchall(),
        }


def create_case(*, title: str, case_type_id: int, forum_id: int, filing_date: date, cnr: str | None,
                summary: str | None, user_id: int) -> int:
    with get_connection() as conn:
        row = conn.execute(
            """INSERT INTO case_file (cnr, case_title, case_type_id, originating_forum_id,
                 current_forum_id, filing_date, subject_summary, created_by_user_id)
               VALUES (%s,%s,%s,%s,%s,%s,%s,%s) RETURNING case_id""",
            (cnr or None, title.strip(), case_type_id, forum_id, forum_id, filing_date, summary or None, user_id),
        ).fetchone()
        # The legacy case_file schema trigger creates FILED history.
        return row["case_id"]


def update_case_details(case_id: int, *, title: str, summary: str | None,
                        court_value: float | None, language_code: str | None,
                        is_confidential: bool) -> int:
    """Update editable descriptive fields without rewriting lifecycle identifiers/history."""
    with get_connection() as conn:
        result = conn.execute("""UPDATE case_file
            SET case_title=%s, subject_summary=%s, court_value=%s,
                language_code=%s, is_confidential=%s, updated_at=CURRENT_TIMESTAMP
            WHERE case_id=%s""",
            (title, summary, court_value, language_code, is_confidential, case_id))
        return result.rowcount


def transition_case(case_id: int, status_code: str, user_id: int, remarks: str) -> None:
    with get_connection() as conn:
        conn.execute("SELECT case_id FROM case_file WHERE case_id=%s FOR UPDATE", (case_id,)).fetchone()
        conn.execute("INSERT INTO case_status_history(case_id,status_code,changed_by_user_id,remarks) VALUES (%s,%s,%s,%s)",
                     (case_id, status_code, user_id, remarks))


def transfer_case(case_id: int, destination_forum_id: int, transfer_date: date, reason: str, user_id: int) -> None:
    with get_connection() as conn:
        case = conn.execute("SELECT current_forum_id FROM case_file WHERE case_id=%s FOR UPDATE", (case_id,)).fetchone()
        if not case:
            raise ValueError("Case was not found.")
        conn.execute("INSERT INTO case_transfer(case_id,from_forum_id,to_forum_id,transfer_date,transfer_reason,approved_by_user_id) VALUES (%s,%s,%s,%s,%s,%s)",
                     (case_id, case["current_forum_id"], destination_forum_id, transfer_date, reason.strip(), user_id))
        # Transfer trigger changes forum and records TRANSFERRED status atomically.
