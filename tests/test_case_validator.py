from datetime import date, timedelta

import pytest

from validators.case_validator import validate_case


def test_valid_case_data() -> None:
    validate_case("A vs B", date.today(), "GJAH0100012025")


def test_case_title_required() -> None:
    with pytest.raises(ValueError, match="title"):
        validate_case("  ", date.today())


def test_filing_date_cannot_be_future() -> None:
    with pytest.raises(ValueError, match="future"):
        validate_case("A vs B", date.today() + timedelta(days=1))


def test_cnr_length_limit() -> None:
    with pytest.raises(ValueError, match="CNR"):
        validate_case("A vs B", date.today(), "X" * 41)
