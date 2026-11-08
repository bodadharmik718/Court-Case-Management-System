"""Transactional e-filing and safe private PDF persistence."""
from __future__ import annotations

from datetime import date
from decimal import Decimal, InvalidOperation
import hashlib
from pathlib import Path
from uuid import uuid4

from config.settings import settings
from database.connection import get_connection
from auth.permissions import require_permission


def _save_pdf(upload: tuple[str, bytes, str]) -> tuple[Path, str, int]:
    filename, content, content_type = upload
    if not filename.lower().endswith(".pdf") or content_type not in {"application/pdf", "application/octet-stream"}:
        raise ValueError("Only PDF documents are accepted.")
    if not content or len(content) > settings.max_upload_bytes or not content.startswith(b"%PDF-"):
        raise ValueError("The file must be a valid PDF within the configured size limit.")
    configured_root = settings.document_storage_path
    root = (configured_root if configured_root.is_absolute() else Path(__file__).resolve().parents[1] / configured_root).resolve()
    target_dir = root / "filings"
    target_dir.mkdir(parents=True, exist_ok=True)
    target = (target_dir / f"{uuid4().hex}.pdf").resolve()
    if root not in target.parents:
        raise ValueError("Invalid document storage location.")
    target.write_bytes(content)
    return target, "application/pdf", len(content)


def submit_petition(*, user: dict, title: str, case_type: str, court_id: int, filing_date: date,
                    description: str, petitioner: dict, respondent: dict,
                    uploads: list[tuple[str, bytes, str]], jurisdiction: str = "",
                    monetary_valuation: str = "") -> tuple[int, str, str]:
    require_permission(user, "FILING_SUBMIT")
    if not user.get("lawyer_id"):
        raise PermissionError("Link this account to a lawyer profile before filing.")
    if not title.strip() or len(title.strip())>255 or not case_type.strip() or len(case_type.strip())>100 or not description.strip() or not petitioner.get("name", "").strip() or not respondent.get("name", "").strip():
        raise ValueError("Case title, filing description, petitioner, and respondent are required.")
    if filing_date > date.today():
        raise ValueError("Filing date cannot be in the future.")
    try:
        valuation=Decimal(monetary_valuation) if monetary_valuation.strip() else None
    except (InvalidOperation,ValueError):
        raise ValueError("Enter a valid monetary valuation.")
    if valuation is not None and (not valuation.is_finite() or valuation<0):
        raise ValueError("Monetary valuation must be a non-negative amount.")
    for party_data in (petitioner,respondent):
        if len(party_data.get("name", "").strip())>150 or len(party_data.get("phone") or "")>25 or len(party_data.get("address") or "")>255:
            raise ValueError("Party name, phone, or address exceeds the supported length.")
    if not uploads:
        raise ValueError("Attach the signed petition PDF.")
    if sum(len(item[1]) for item in uploads)>settings.max_upload_bytes:
        raise ValueError("The combined upload size exceeds the configured limit.")

    saved_files=[]
    try:
        for item in uploads:
            saved_files.append((*_save_pdf(item),item))
        with get_connection() as conn:
            alloc = conn.execute("""WITH new_id AS (SELECT nextval(pg_get_serial_sequence('court_case','case_id'))::INTEGER AS id)
                INSERT INTO court_case(case_id,cuid,cnr,case_title,case_type,filing_date,court_id,public_access,jurisdiction_note,monetary_valuation)
                SELECT id,'CUID-'||%s||'-'||lpad(id::text,8,'0'),'CNR/'||%s||'/'||%s||'/'||lpad(id::text,8,'0'),%s,%s,%s,%s,FALSE,%s,%s
                FROM new_id RETURNING case_id,cuid,cnr""",
                (filing_date.year,court_id,filing_date.year,title.strip(),case_type,filing_date,court_id,jurisdiction.strip() or None,valuation)).fetchone()
            case_id = alloc["case_id"]
            parties = []
            for party_data, party_type in ((petitioner,"Petitioner"),(respondent,"Respondent")):
                phone=party_data.get("phone") or None
                party=None
                if phone:
                    party=conn.execute("""SELECT party_id FROM party WHERE lower(trim(party_name))=lower(trim(%s))
                        AND phone=%s ORDER BY party_id LIMIT 1 FOR UPDATE""",(party_data["name"].strip(),phone)).fetchone()
                if not party:
                    party=conn.execute("""INSERT INTO party(party_name,party_type,phone,address)
                        VALUES (%s,%s,%s,%s) RETURNING party_id""",
                        (party_data["name"].strip(),party_type,phone,party_data.get("address") or None)).fetchone()
                party_id=party["party_id"]
                parties.append(party_id)
                conn.execute("INSERT INTO case_party(case_id,party_id) VALUES (%s,%s) ON CONFLICT DO NOTHING",(case_id,party_id))
            lawyer_id = user["lawyer_id"]
            conn.execute("INSERT INTO lawyer_case(lawyer_id,case_id,representation_start_date) VALUES (%s,%s,%s)",(lawyer_id,case_id,filing_date))
            conn.execute("INSERT INTO lawyer_party(lawyer_id,party_id) VALUES (%s,%s) ON CONFLICT DO NOTHING",(lawyer_id,parties[0]))
            filing = conn.execute("""INSERT INTO petition(subject,verification_status,case_id,lawyer_id,submitted_by_user_id,submitted_at,filing_status,filing_remarks)
                VALUES (%s,'Pending',%s,%s,%s,CURRENT_TIMESTAMP,'PENDING_SCRUTINY',%s) RETURNING petition_id""",
                (title.strip(),case_id,lawyer_id,user["user_id"],description.strip())).fetchone()
            for index,(saved_path,content_type,size,upload) in enumerate(saved_files):
                checksum = hashlib.sha256(upload[1]).hexdigest()
                safe_title=Path(upload[0].replace("\\","/")).name[:255]
                doc_type="Petition" if index==0 else "Supporting document"
                conn.execute("""INSERT INTO document(title,document_type,file_path,verification_status,confidentiality_level,case_id,content_type,file_size_bytes,checksum_sha256,uploaded_by_user_id,is_public)
                    VALUES (%s,%s,%s,'Pending','CONFIDENTIAL',%s,%s,%s,%s,%s,FALSE)""",
                    (safe_title,doc_type,saved_path.as_posix(),case_id,content_type,size,checksum,user["user_id"]))
            conn.execute("INSERT INTO case_status_history(case_id,transition_timestamp,previous_status,new_status,transition_remarks,user_id) VALUES (%s,CURRENT_TIMESTAMP,NULL,'Filed','Electronic filing submitted for scrutiny',%s)",(case_id,user["user_id"]))
            conn.execute("INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state) VALUES ('E_FILING_SUBMITTED',%s,%s,'CREATE','petition',%s,%s)",(user["user_id"],case_id,filing["petition_id"],alloc["cuid"]+' | '+alloc["cnr"]))
            return case_id,alloc["cuid"],alloc["cnr"]
    except Exception:
        for saved_path,_,_,_ in saved_files:
            saved_path.unlink(missing_ok=True)
        raise
