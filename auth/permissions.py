"""Database-backed permission and record-scope enforcement."""
from datetime import datetime, timezone

from database.connection import get_connection


def has_permission(user: dict, permission_code: str, *, case_id: int | None = None) -> bool:
    with get_connection() as conn:
        account = conn.execute("""SELECT u.user_id,u.role_id,r.role_name,u.account_status,u.locked_until,u.judge_id,u.clerk_id,u.lawyer_id,u.court_id
            FROM app_user u JOIN role r USING(role_id) WHERE u.user_id=%s""",(user["user_id"],)).fetchone()
        if not account or account["account_status"].lower() != "active" or (
            account["locked_until"] and account["locked_until"] > datetime.now(timezone.utc)
        ):
            return False
        user = {**user,**account}
        role=user["role_name"].strip().lower()
        if permission_code=="REPORT_VIEW" and role in {"presiding judge","court clerk","court master / bench clerk","advocate","advocate / legal counsel","police & prison liaison"}:
            return False
        if permission_code=="NOTIFICATION_MANAGE" and role in {"advocate","advocate / legal counsel"}:
            return False
        if permission_code=="FILING_SUBMIT" and role in {"registry clerk","filing & scrutiny clerk","court clerk","court master / bench clerk"}:
            return False
        allowed = conn.execute("""SELECT EXISTS(
            SELECT 1 FROM role_permission rp
            JOIN app_permission p USING(permission_id)
            WHERE rp.role_id=%s AND p.permission_code=%s
        ) AS allowed""", (user["role_id"], permission_code)).fetchone()["allowed"]
        if not allowed:
            return False
        if case_id is None:
            return True
        role = user["role_name"].strip().lower()
        if role in {"system administrator", "registry clerk", "filing & scrutiny clerk", "read-only auditor"}:
            return True
        if role in {"court clerk", "court master / bench clerk"}:
            return bool(user.get("court_id") and conn.execute(
                "SELECT EXISTS(SELECT 1 FROM court_case WHERE case_id=%s AND court_id=%s AND archived_at IS NULL) AS allowed",
                (case_id,user["court_id"])).fetchone()["allowed"])
        if role == "police & prison liaison":
            return bool(user.get("court_id") and conn.execute(
                "SELECT EXISTS(SELECT 1 FROM court_case WHERE case_id=%s AND court_id=%s AND archived_at IS NULL) AS allowed",
                (case_id,user["court_id"])).fetchone()["allowed"])
        if role in {"advocate", "advocate / legal counsel"} and permission_code == "ADJOURNMENT_REQUEST":
            return bool(user.get("lawyer_id") and conn.execute(
                "SELECT EXISTS(SELECT 1 FROM lawyer_case WHERE case_id=%s AND lawyer_id=%s) AS allowed",
                (case_id,user["lawyer_id"])).fetchone()["allowed"])
        if role == "presiding judge":
            if not user.get("judge_id"):
                return False
            return conn.execute("""SELECT EXISTS(
                SELECT 1 FROM hearing h JOIN bench_judge bj USING(bench_id)
                WHERE h.case_id=%s AND bj.judge_id=%s
                UNION ALL
                SELECT 1 FROM case_bench_assignment cba JOIN bench_judge bj USING(bench_id)
                WHERE cba.case_id=%s AND cba.ended_at IS NULL AND bj.judge_id=%s
            ) AS allowed""", (case_id,user["judge_id"],case_id,user["judge_id"])).fetchone()["allowed"]
        if role in {"advocate", "advocate / legal counsel"}:
            if not user.get("lawyer_id"):
                return False
            return conn.execute("""SELECT EXISTS(SELECT 1 FROM lawyer_case WHERE case_id=%s AND lawyer_id=%s) AS allowed""",
                                (case_id,user["lawyer_id"])).fetchone()["allowed"]
        if role == "public user":
            return permission_code == "PUBLIC_CASE_READ" and conn.execute("""SELECT EXISTS(
                SELECT 1 FROM court_case WHERE case_id=%s AND public_access AND NOT is_confidential AND archived_at IS NULL
            ) AS allowed""", (case_id,)).fetchone()["allowed"]
        return False


def require_permission(user: dict, permission_code: str, *, case_id: int | None = None) -> None:
    if not has_permission(user, permission_code, case_id=case_id):
        raise PermissionError("Your account is not permitted to perform this action on the selected record.")


def require_active_case(case_id: int) -> None:
    with get_connection() as conn:
        active=conn.execute("SELECT archived_at IS NULL AS active FROM court_case WHERE case_id=%s",(case_id,)).fetchone()
        if not active or not active["active"]:
            raise PermissionError("Archived or missing cases cannot be modified.")
