"""Legacy courtroom helpers retained for the superseded schema."""
from database.connection import get_connection


def list_courtrooms() -> list[dict]:
    with get_connection() as conn:
        return conn.execute("""SELECT cr.courtroom_id, cr.forum_id, f.forum_name,
              cr.room_code, cr.room_name, cr.floor_number, cr.capacity, cr.is_active
            FROM courtroom cr JOIN forum f USING (forum_id)
            ORDER BY f.forum_name, cr.room_code""").fetchall()


def create_demo_courtroom(forum_id: int, room_code: str, room_name: str,
                          floor_number: str | None, capacity: int | None) -> int:
    with get_connection() as conn:
        row = conn.execute("""INSERT INTO courtroom(forum_id,room_code,room_name,floor_number,capacity)
            VALUES (%s,%s,%s,%s,%s) RETURNING courtroom_id""",
            (forum_id, room_code, room_name, floor_number, capacity)).fetchone()
        return row["courtroom_id"]


def update_demo_courtroom(courtroom_id: int, room_name: str,
                          floor_number: str | None, capacity: int | None) -> int:
    with get_connection() as conn:
        result = conn.execute("""UPDATE courtroom SET room_name=%s, floor_number=%s, capacity=%s
            WHERE courtroom_id=%s AND room_code LIKE 'LAB-DEMO-%'""",
            (room_name, floor_number, capacity, courtroom_id))
        return result.rowcount


def delete_demo_courtroom(courtroom_id: int) -> int:
    with get_connection() as conn:
        room = conn.execute("SELECT courtroom_id FROM courtroom WHERE courtroom_id=%s AND room_code LIKE 'LAB-DEMO-%' FOR UPDATE",
                            (courtroom_id,)).fetchone()
        if not room:
            return 0
        in_use = conn.execute("SELECT EXISTS(SELECT 1 FROM hearing WHERE courtroom_id=%s) AS in_use",
                              (courtroom_id,)).fetchone()["in_use"]
        if in_use:
            raise ValueError("This demo courtroom has hearing records and cannot be deleted.")
        result = conn.execute("DELETE FROM courtroom WHERE courtroom_id=%s AND room_code LIKE 'LAB-DEMO-%'",
                              (courtroom_id,))
        return result.rowcount
