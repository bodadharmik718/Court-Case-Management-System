from datetime import date


def validate_case(title: str, filing_date: date, cnr: str | None = None) -> None:
    if not title or not title.strip():
        raise ValueError("Case title is required.")
    if len(title.strip()) > 500:
        raise ValueError("Case title must be 500 characters or fewer.")
    if filing_date > date.today():
        raise ValueError("Filing date cannot be in the future.")
    if cnr and len(cnr.strip()) > 40:
        raise ValueError("CNR must be 40 characters or fewer.")
