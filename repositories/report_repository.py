from database.connection import get_connection


def postgres_version() -> str:
    with get_connection() as conn:
        return conn.execute("SELECT version() AS server_version").fetchone()["server_version"]


def dashboard_metrics() -> dict:
    with get_connection() as conn:
        row = conn.execute("""SELECT
          (SELECT COUNT(*) FROM case_file) total_cases,
          (SELECT COUNT(*) FROM v_pending_case_dashboard) pending_cases,
          (SELECT COUNT(*) FROM v_case_current_status vcs JOIN case_status s ON s.status_code=vcs.current_status_code WHERE s.is_terminal) disposed_cases,
          (SELECT COUNT(*) FROM case_file WHERE filing_date >= date_trunc('month',CURRENT_DATE)) filed_month,
          (SELECT COUNT(*) FROM hearing WHERE hearing_date=CURRENT_DATE AND hearing_status='SCHEDULED') hearings_today,
          (SELECT COUNT(*) FROM hearing WHERE hearing_date>CURRENT_DATE AND hearing_status='SCHEDULED') upcoming_hearings,
          (SELECT COUNT(*) FROM case_filing WHERE filing_status_code IN ('SUBMITTED','UNDER_SCRUTINY')) awaiting_scrutiny,
          (SELECT COUNT(*) FROM filing_defect WHERE defect_status='OPEN') open_defects,
          (SELECT COUNT(*) FROM evidence_item WHERE admission_status='PENDING') evidence_pending""").fetchone()
        return row


def report_data() -> dict[str, list[dict]]:
    sql = {
      "Pending by court": "SELECT current_forum_name, category_name, COUNT(*) pending_cases FROM v_pending_case_dashboard GROUP BY 1,2 ORDER BY 1,2",
      "Case distribution": "SELECT current_status_name, case_type_name, COUNT(*) case_count FROM v_case_current_status GROUP BY 1,2 ORDER BY 1,2",
      "Upcoming hearings": "SELECT * FROM v_upcoming_hearings ORDER BY hearing_date,start_time LIMIT 500",
      "Open filing defects": "SELECT * FROM v_open_filing_defects ORDER BY cure_deadline NULLS LAST",
      "Evidence review queue": "SELECT * FROM v_evidence_review_queue ORDER BY submission_date",
      "Adjournments": "SELECT * FROM v_case_adjournment_summary WHERE approved_adjournments > 3 ORDER BY approved_adjournments DESC",
      "No upcoming hearing": "SELECT p.case_id,p.cnr,p.case_title,p.current_forum_name,p.current_status_name,p.filing_date FROM v_pending_case_dashboard p WHERE NOT EXISTS (SELECT 1 FROM hearing h WHERE h.case_id=p.case_id AND h.hearing_date>=CURRENT_DATE AND h.hearing_status='SCHEDULED') ORDER BY p.filing_date",
      "Judge upcoming workload": "SELECT * FROM v_judge_upcoming_hearing_load ORDER BY upcoming_hearings DESC",
      "Disposal duration": "SELECT * FROM v_case_disposal_time ORDER BY days_to_first_final_judgment DESC NULLS LAST",
      "Transferred cases": "SELECT c.case_id,c.cnr,c.case_title,src.forum_name from_forum,dst.forum_name to_forum,ct.transfer_date,ct.transfer_reason FROM case_transfer ct JOIN case_file c USING(case_id) JOIN forum src ON src.forum_id=ct.from_forum_id JOIN forum dst ON dst.forum_id=ct.to_forum_id ORDER BY ct.transfer_date DESC",
    }
    with get_connection() as conn:
        return {name: conn.execute(query).fetchall() for name, query in sql.items()}
