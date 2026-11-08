import hashlib
import re
import uuid
from pathlib import Path

from config.settings import ROOT, settings
from database.connection import get_connection


def save_pdf(user_id: int, case_id: int, title: str, document_type_code: str, confidentiality: str,
             uploaded_name: str, content: bytes) -> int:
    from auth.authorization import require_permission
    require_permission(user_id, "CASE_UPDATE", case_id=case_id)
    if not uploaded_name.lower().endswith(".pdf") or not content.startswith(b"%PDF-"):
        raise ValueError("Only valid PDF files are accepted.")
    if not content or len(content) > settings.max_upload_bytes:
        raise ValueError(f"PDF must be smaller than {settings.max_upload_bytes // (1024*1024)} MB.")
    safe_name = re.sub(r"[^A-Za-z0-9._-]", "_", Path(uploaded_name).name)[:180] or "document.pdf"
    key = f"{case_id}/{uuid.uuid4().hex}_{safe_name}"
    storage_root = (ROOT / settings.document_storage_path).resolve() if not settings.document_storage_path.is_absolute() else settings.document_storage_path.resolve()
    target = (storage_root / key).resolve()
    if storage_root not in target.parents:
        raise ValueError("Invalid storage path.")
    target.parent.mkdir(parents=True, exist_ok=True)
    checksum = hashlib.sha256(content).hexdigest()
    try:
        target.write_bytes(content)
        with get_connection() as conn:
            doc = conn.execute("""INSERT INTO document(case_id,document_type_code,title,confidentiality_level,created_by_user_id)
                 VALUES (%s,%s,%s,%s,%s) RETURNING document_id""",
                 (case_id, document_type_code, title.strip(), confidentiality, user_id)).fetchone()
            conn.execute("INSERT INTO case_document(case_id,document_id) VALUES (%s,%s)", (case_id, doc["document_id"]))
            conn.execute("""INSERT INTO document_version(document_id,version_number,storage_key,original_file_name,mime_type,file_size_bytes,checksum_sha256,uploaded_by_user_id)
                 VALUES (%s,1,%s,%s,'application/pdf',%s,%s,%s)""",
                 (doc["document_id"], key, safe_name, len(content), checksum, user_id))
        return doc["document_id"]
    except Exception:
        target.unlink(missing_ok=True)
        raise


def read_document(user_id: int, case_id: int, document_id: int) -> tuple[str, bytes]:
    """Return a permitted document's filename and bytes without exposing a public URL."""
    from auth.authorization import require_permission
    with get_connection() as conn:
        row = conn.execute("""SELECT d.confidentiality_level,d.public_visible,v.storage_key,v.original_file_name
            FROM document d JOIN case_document cd USING(document_id)
            JOIN LATERAL (SELECT storage_key,original_file_name FROM document_version
              WHERE document_id=d.document_id ORDER BY version_number DESC LIMIT 1) v ON TRUE
            WHERE d.document_id=%s AND cd.case_id=%s AND d.is_active""", (document_id, case_id)).fetchone()
    if not row:
        raise ValueError("Document was not found.")
    if not (row["public_visible"] and row["confidentiality_level"] == "PUBLIC"):
        require_permission(user_id, "DOCUMENT_PRIVATE_READ", case_id=case_id)
    root = (ROOT / settings.document_storage_path).resolve() if not settings.document_storage_path.is_absolute() else settings.document_storage_path.resolve()
    path = (root / row["storage_key"]).resolve()
    if root not in path.parents or not path.is_file():
        raise FileNotFoundError("The protected document file is unavailable.")
    return row["original_file_name"], path.read_bytes()
