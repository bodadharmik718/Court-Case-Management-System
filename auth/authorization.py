from database.connection import get_connection


def has_permission(user_id: int, permission_code: str, *, forum_id: int | None = None, case_id: int | None = None) -> bool:
    """Legacy authorization helper for the superseded role-assignment schema."""
    with get_connection() as conn:
        return conn.execute(
            """SELECT EXISTS (
                 SELECT 1 FROM user_role_assignment ura
                 JOIN role_permission rp USING (role_code)
                 WHERE ura.user_id = %s AND rp.permission_code = %s
                   AND ura.valid_from <= CURRENT_TIMESTAMP
                   AND (ura.valid_to IS NULL OR ura.valid_to >= CURRENT_TIMESTAMP)
                   AND ((%s::BIGINT IS NULL AND %s::BIGINT IS NULL) OR ura.forum_id IS NULL OR ura.forum_id = COALESCE(%s::BIGINT, (SELECT current_forum_id FROM case_file WHERE case_id = %s::BIGINT)))
                   AND (%s::BIGINT IS NULL OR ura.case_id IS NULL OR ura.case_id = %s::BIGINT)
               ) AS allowed""", (user_id, permission_code, forum_id, case_id, forum_id, case_id, case_id, case_id)
        ).fetchone()["allowed"]


def require_permission(user_id: int, permission_code: str, *, forum_id: int | None = None, case_id: int | None = None) -> None:
    if not has_permission(user_id, permission_code, forum_id=forum_id, case_id=case_id):
        raise PermissionError(f"You do not have permission to {permission_code.lower().replace('_', ' ')}.")
