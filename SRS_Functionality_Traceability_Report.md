# CCMS SRS V4 traceability

**Review date:** 7 November 2026  
**Basis:** SRS V4 and the current app, services, repositories, and additive migration. This is a source review; the migration has not been executed against the populated database.

| SRS | Functionality | Status | Location and remaining gap |
|---|---|---|---|
| FR-01 | Electronic case filing | **Partial** | `services/filing_service.py`, E-Filing page. Advocate submits case, petitioner/respondent, representation, petition and PDFs transactionally. Vakalatnama/e-signature validation and litigant self-service are absent. |
| FR-02 | Case/party indexing | **Partial** | `repositories/coursework_case_repository.py`, `services/filing_service.py`. Generated case metadata and party links/search work; comprehensive party editing and role/type association per case are limited by the base relationship schema. |
| FR-03 | Automatic CUID/CNR | **Implemented** | Filing and registry insert allocate identity and generate stable unique identifiers; database uniqueness constraints remain authoritative. |
| FR-04 | Registry scrutiny and fees | **Partial** | `services/filing_review_service.py`, `services/fee_service.py`. Clerks approve/return filings and enter manual assessments/results. Statutory fee schedule/payment gateway are unavailable. |
| FR-05 | Defects, notices, cure window | **Partial** | Scrutiny creates defects with seven calendar days and queues email; clerks can resolve them. Sending requires SMTP and valid email; no SMS or court-business-day calendar. |
| FR-06 | Judge/bench allocation | **Partial** | `services/scheduling_service.py` supports historical case-to-bench assignments. Judge roster/workload management is not included. |
| FR-07 | Hearing conflicts and cause lists | **Partial** | `services/scheduling_service.py`, `services/judicial_service.py`. Schedule checks room/judge overlaps and court holidays; cause lists can be published. Calendar view, edit/reschedule UI beyond adjournment, and live courtroom display are absent. |
| FR-08 | Proceedings, attendance, outcome | **Partial** | Proceedings, outcome, next date, and one selected participant attendance can be entered and audited. Witness testimony and broader attendance imports are absent. |
| FR-09 | Orders, judgments, PKI | **Partial** | `services/judicial_service.py` creates unsigned drafts and protects signed content; publication requires a stored signature hash. PKI signing/verification and QR verification are unavailable. |
| FR-10 | Search and full case retrieval | **Partial** | Case/party/reference search and case status, parties, counsel, filings, hearings, orders, judgments, documents, and authorized audit data are available. Pagination and complete evidence/witness docket UI remain absent. |
| FR-11 | Public portal | **Partial** | Unauthenticated portal only returns explicitly published, non-confidential, non-archived cases, cause lists, and signature-hash-present public orders/judgments. Signature cryptographic validity is not independently verified. |
| FR-12 | Notifications | **Partial** | Defect/hearing notices are queued; `services/notification_service.py` can explicitly send email through configured SMTP, records attempts, and retries failures up to three times. SMS and provider delivery guarantees are absent. |
| FR-13 | Append-only audit | **Partial** | Core case, filing, user, hearing, order, fee, notification, and liaison operations write audit rows; triggers reject updates/deletes. Some legacy or not-yet-built operations do not emit events. |
| FR-14 | Indefinite WORM archive | **Partial** | Archive metadata preserves case and linked rows; database blocks case deletion and edits after archive. External WORM/immutable object storage and retention certification are not available. |

## Non-functional requirements

| Area | Status | Notes |
|---|---|---|
| Authentication and RBAC | **Partial** | Argon2id, active status, failed-login lockout support, database role permissions, role navigation, and backend permission/scope checks. Requires migration and administrator profile linking. |
| Integrity and transaction safety | **Partial** | Multi-table filing is transactional; migrations preserve data; FK/check constraints, unique identifiers, conflict checks, and append-only guards are added. No live database migration validation yet. |
| Availability and recovery | **Missing** | Local Streamlit execution only; no backup scheduler, recovery runbook, or production uptime. |
| Performance and scale | **Unverified** | Basic indexes and bounded results exist. No load test or tens-of-thousands record benchmark. |
| Privacy/redaction | **Partial** | Public visibility defaults false, confidential cases are excluded, private documents are authorization-gated. No content redaction or judicial sealing workflow. |
| Maintainability | **Partial** | Auth, repositories, and workflow services are modularized; the Streamlit entry file still owns multiple page layouts. |

## External or policy inputs still needed

Configure SMTP for email delivery. SMS, PKI certificates/signing, QR verification, WORM storage, payment processing, statutory fee schedules, business-day deadline rules, and police/prison APIs need real provider/policy details. The app does not fabricate these integrations. Seeded users must be linked to existing judge/clerk/lawyer/court profiles through User administration.

## Verification status

`python -m compileall .` succeeded. `python -m pytest -q --basetemp=.pytest_cache/test-tmp` passed (17 tests). These tests use mocks/local temporary files only; they do not validate PostgreSQL SQL or modify the user's populated database. Apply the migration only to the intended CCMS database after backing it up.
