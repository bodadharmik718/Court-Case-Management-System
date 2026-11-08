"""Database-backed fee assessment; no statutory rate or payment provider is assumed."""
from decimal import Decimal, InvalidOperation

from auth.permissions import require_active_case, require_permission
from database.connection import get_connection


def list_case_fees(*, user: dict, case_id: int) -> list[dict]:
    require_permission(user,"CASE_READ",case_id=case_id)
    with get_connection() as conn:
        return conn.execute("SELECT fee_id,petition_id,amount,currency,assessment_note,status,payment_reference,assessed_at,paid_at FROM case_fee_assessment WHERE case_id=%s ORDER BY assessed_at DESC",(case_id,)).fetchall()


def assess_fee(*, user: dict, case_id: int, petition_id: int | None, amount: str, currency: str, note: str) -> int:
    require_permission(user,"FEE_MANAGE",case_id=case_id)
    try:
        fee_amount=Decimal(amount)
    except (InvalidOperation,ValueError):
        raise ValueError("Enter a valid non-negative fee amount.")
    if not fee_amount.is_finite() or fee_amount < 0 or not note.strip() or len(currency.strip())!=3:
        raise ValueError("Fee amount, three-letter currency, and assessment note are required.")
    require_active_case(case_id)
    with get_connection() as conn:
        row=conn.execute("INSERT INTO case_fee_assessment(case_id,petition_id,amount,currency,assessment_note,assessed_by_user_id) VALUES (%s,%s,%s,%s,%s,%s) RETURNING fee_id",
            (case_id,petition_id,fee_amount,currency.strip().upper(),note.strip(),user["user_id"])).fetchone()
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES ('FEE_ASSESSED',%s,%s,'CREATE','case_fee_assessment',%s,%s)",(user["user_id"],case_id,row["fee_id"],f'{fee_amount} {currency.upper()}'))
        return row["fee_id"]


def record_fee_result(*, user: dict, fee_id: int, status: str, reference: str = "") -> None:
    require_permission(user,"FEE_MANAGE")
    status=status.upper()
    if status not in {"PAID","WAIVED"} or (status=="PAID" and not reference.strip()):
        raise ValueError("Choose paid or waived. A payment reference is required for paid fees.")
    with get_connection() as conn:
        row=conn.execute("SELECT case_id,status FROM case_fee_assessment WHERE fee_id=%s FOR UPDATE",(fee_id,)).fetchone()
        if not row or row["status"]!="DUE":
            raise ValueError("Only a due fee can be marked paid or waived.")
        require_permission(user,"FEE_MANAGE",case_id=row["case_id"])
        require_active_case(row["case_id"])
        conn.execute("UPDATE case_fee_assessment SET status=%s,payment_reference=%s,paid_at=CASE WHEN %s='PAID' THEN CURRENT_TIMESTAMP ELSE NULL END WHERE fee_id=%s",
            (status,reference.strip() or None,status,fee_id))
        conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES (%s,%s,%s,'UPDATE','case_fee_assessment',%s,%s)",(f'FEE_{status}',user["user_id"],row["case_id"],fee_id,reference.strip() or status))
