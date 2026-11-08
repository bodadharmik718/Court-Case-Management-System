from types import SimpleNamespace

import pytest

from services import filing_service


def test_pdf_upload_uses_private_generated_path(monkeypatch, tmp_path) -> None:
    monkeypatch.setattr(filing_service, "settings", SimpleNamespace(
        document_storage_path=tmp_path / "private", max_upload_bytes=1024
    ))
    path, mime, size = filing_service._save_pdf(("../../petition.pdf", b"%PDF-1.7\ncontent", "application/pdf"))
    assert path.is_file()
    assert path.parent.name == "filings"
    assert "petition" not in path.name
    assert path.read_bytes().startswith(b"%PDF-")
    assert mime == "application/pdf"
    assert size == len(b"%PDF-1.7\ncontent")


@pytest.mark.parametrize("upload", [
    ("petition.exe", b"%PDF-1.7", "application/pdf"),
    ("petition.pdf", b"not a pdf", "application/pdf"),
    ("petition.pdf", b"%PDF-1.7", "text/plain"),
])
def test_pdf_upload_rejects_invalid_type_or_content(monkeypatch, tmp_path, upload) -> None:
    monkeypatch.setattr(filing_service, "settings", SimpleNamespace(
        document_storage_path=tmp_path / "private", max_upload_bytes=1024
    ))
    with pytest.raises(ValueError):
        filing_service._save_pdf(upload)


def test_pdf_upload_enforces_size(monkeypatch, tmp_path) -> None:
    monkeypatch.setattr(filing_service, "settings", SimpleNamespace(
        document_storage_path=tmp_path / "private", max_upload_bytes=5
    ))
    with pytest.raises(ValueError, match="size"):
        filing_service._save_pdf(("petition.pdf", b"%PDF-1.7", "application/pdf"))
