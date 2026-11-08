from contextlib import nullcontext
from datetime import date, time

import pytest

from repositories import coursework_case_repository as cases
from services import fee_service, filing_service, scheduling_service


class FakeConnection:
    def __init__(self):
        self.queries = []

    def execute(self, query, params=()):
        self.queries.append((query, params))
        if "WITH new_id AS" in query:
            return FakeResult({"case_id": 43})
        return FakeResult({"ok": True})


class FakeResult:
    def __init__(self, row):
        self.row = row

    def fetchone(self):
        return self.row


def test_case_registration_is_transactional_and_audited(monkeypatch):
    fake = FakeConnection()
    monkeypatch.setattr(cases, "_account_for_user", lambda user_id: {"role_id": 1, "role_name": "System Administrator"})
    monkeypatch.setattr(cases, "require_permission", lambda *args, **kwargs: None)
    monkeypatch.setattr(cases, "get_connection", lambda: nullcontext(fake))
    case_id = cases.create_case(case_title="A v B", case_type="Civil", filing_date=date(2026, 1, 1), court_id=2, user_id=1)
    assert case_id == 43
    sql = "\n".join(query for query, _ in fake.queries)
    assert "CUID-" in sql and "CNR/" in sql
    assert "INSERT INTO case_status_history" in sql
    assert "INSERT INTO audit_log" in sql


def test_filing_requires_linked_advocate_before_writing(monkeypatch):
    monkeypatch.setattr(filing_service, "require_permission", lambda *args, **kwargs: None)
    with pytest.raises(PermissionError, match="lawyer profile"):
        filing_service.submit_petition(
            user={"user_id": 5, "lawyer_id": None}, title="A v B", case_type="Civil", court_id=1,
            filing_date=date.today(), description="Filing", petitioner={"name": "A"}, respondent={"name": "B"},
            uploads=[("petition.pdf", b"%PDF-1.7", "application/pdf")],
        )


def test_fee_assessment_rejects_invalid_amount_before_database(monkeypatch):
    monkeypatch.setattr(fee_service, "require_permission", lambda *args, **kwargs: None)
    with pytest.raises(ValueError, match="valid non-negative"):
        fee_service.assess_fee(user={"user_id": 1}, case_id=1, petition_id=None, amount="not-money", currency="INR", note="Fee")


def test_scheduling_rejects_invalid_time_range_before_database(monkeypatch):
    monkeypatch.setattr(scheduling_service, "require_permission", lambda *args, **kwargs: None)
    with pytest.raises(ValueError, match="valid time range"):
        scheduling_service.schedule_hearing(
            user={"user_id": 1}, case_id=1, hearing_date=date.today(), start_time=time(11, 0),
            end_time=time(10, 0), room_id=1, bench_id=1, purpose="Hearing",
        )
