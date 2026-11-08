# CCMS implementation checklist

This checklist tracks work against the master implementation prompt. “Implemented” means an app/service/database workflow exists; it does not imply a live PostgreSQL migration has been run.

## Foundation and security

- [x] Preserve the existing 31-table schema; add an idempotent migration only.
- [x] Add role-to-permission mapping and missing SRS roles without renaming seeded roles.
- [x] Add user-to-judge/clerk/lawyer/court associations and administrator account/profile management.
- [x] Keep Argon2id login, account status checks, failed-login lockout support, logout/auth event logs.
- [x] Enforce role and record scope in repository/service operations.
- [x] Prevent hard case deletion; archive closed/disposed cases and protect audit/status/signed records.
- [x] Keep private uploaded files inside configured storage and gate downloads by authorization.

## Functional requirements

- [x] Dashboard uses live PostgreSQL queries; scoped roles see assigned/court matters.
- [x] E-filing with petitioner/respondent, advocate representation, petition and PDF supporting documents in one transaction.
- [x] Generate unique CUID/CNR references on registration.
- [x] Registry scrutiny approve/return workflow, defect tracking, seven-calendar-day cure date.
- [x] Manual fee assessment and recorded paid/waived result (no supplied statutory tariff/payment provider).
- [x] Case-to-bench assignment history.
- [x] Hearing scheduling, room/judge overlap prevention, court holiday check, and cause-list publish.
- [x] Proceedings, outcome, next date, and participant attendance.
- [x] Order/judgment drafts, signature-hash publication gate, and signed-content guards.
- [x] Search case references/parties and view authorized history/docket records.
- [x] Public unauthenticated search for explicitly published non-confidential cases, cause lists, and signed-hash orders/judgments.
- [x] Queue email notices; SMTP dispatch is explicit and optional with attempt logging and bounded retry.
- [x] Audit critical case, user, filing, hearing, fee, order, notification, and liaison events.
- [x] Case transfer history and party adjournment cap/review workflow.
- [x] Police/prison liaison status records (no external agency exchange).

## External dependencies / remaining limits

- [ ] Configure and validate real SMTP and SMS gateways.
- [ ] Integrate PKI signature creation/verification and QR verification.
- [ ] Provide WORM/object-lock storage and retention certification.
- [ ] Confirm statutory fee tables, court business-day deadline policy, and payment gateway.
- [ ] Integrate external police/prison systems.
- [ ] Add field-level public redaction, high-volume pagination, and load testing.
- [ ] Run the additive migration and workflow checks on a separate test database, not the populated coursework database.

## Verification performed

- [x] `python -m compileall .` — passed.
- [x] `python -m pytest -q --basetemp=.pytest_cache/test-tmp` — 17 passed.
- [ ] PostgreSQL migration/runtime validation — not performed; the user’s database was not modified.
