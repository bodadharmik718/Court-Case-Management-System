"""Authorized courtroom CRUD for the Lab 11 database connectivity demo."""
from auth.authorization import require_permission
from repositories.courtroom_repository import (
    create_demo_courtroom, delete_demo_courtroom, list_courtrooms, update_demo_courtroom,
)


def get_courtrooms(user: dict) -> list[dict]:
    require_permission(user["user_id"], "COURT_MANAGE")
    return list_courtrooms()


def add_demo_courtroom(user: dict, forum_id: int, code: str, name: str,
                       floor: str | None, capacity: int | None) -> int:
    require_permission(user["user_id"], "COURT_MANAGE", forum_id=forum_id)
    if not code.startswith("LAB-DEMO-"):
        raise ValueError("Room codes must start with LAB-DEMO- so only disposable lab records can be deleted.")
    if not name.strip():
        raise ValueError("Room name is required.")
    if capacity is not None and capacity < 1:
        raise ValueError("Capacity must be a positive number.")
    return create_demo_courtroom(forum_id, code.strip(), name.strip(), floor or None, capacity)


def edit_demo_courtroom(user: dict, courtroom_id: int, name: str,
                        floor: str | None, capacity: int | None) -> int:
    require_permission(user["user_id"], "COURT_MANAGE")
    if not name.strip():
        raise ValueError("Room name is required.")
    if capacity is not None and capacity < 1:
        raise ValueError("Capacity must be a positive number.")
    return update_demo_courtroom(courtroom_id, name.strip(), floor or None, capacity)


def remove_demo_courtroom(user: dict, courtroom_id: int) -> int:
    require_permission(user["user_id"], "COURT_MANAGE")
    return delete_demo_courtroom(courtroom_id)
