# CCMS V5 - Database Design and Data Dictionary

**Project:** Judiciary / Court Case Management System (CCMS)  
**Database:** PostgreSQL 14+  
**Application stack selected:** Python + PostgreSQL + Streamlit  
**Design scope:** India-oriented, multi-forum judicial case management; configurable for different court and tribunal structures.  
**AI integration:** Not included in this version.

---

## 1. What this database is designed to answer

The database is intended to answer operational and administrative questions that can be answered from recorded court data, including:

- Which cases are pending in each court, court type, jurisdiction, case category or case type?
- Which cases are oldest, overdue, stayed, reserved for judgment, transferred or disposed?
- Which cases have no future hearing, and what is listed in a court's cause list on a particular date?
- What is each judge's upcoming hearing load and bench assignment history?
- How many cases has a judge, lawyer, court or bench handled during a selected period?
- How long do cases take to reach a final judgment, broken down by court and case type?
- Which cases have frequent adjournments, and what are the reasons and outcomes of those requests?
- Which filings are awaiting scrutiny, verification, registration or correction?
- Which filing defects are open, cured, waived or overdue?
- Which parties are involved in a case, in what legal role, and which lawyers currently represent them?
- Which lawyers have active representation, what specializations are recorded, and how many active matters do they handle?
- Which evidence items are pending, admitted, not admitted or marked for identification?
- What is the review and chain-of-custody history of an evidence item?
- Which witnesses have been summoned, whether summons were served, and whether they attended or testified?
- Which orders and judgments were issued in a case, and which appeals challenge them?
- Which legal provisions are associated with a case?
- What court fees remain due, what payments were received, and which notifications failed?
- Who created, viewed or changed a record, when it happened, and what changed?
- Are two hearings scheduled in the same courtroom or before the same judge at overlapping times?

**Important limitation:** No database can answer literally every possible question about a court. It can answer questions whose underlying facts are captured in its tables and which the logged-in user is authorized to see. This design focuses on operational case-management questions and analytics. It is not a legal-advice engine, a judgment-prediction system, or a replacement for official court records.

## 2. Files included

| File | Purpose |
|---|---|
| `CCMS_V5_schema.sql` | Complete PostgreSQL DDL, lookup data, constraints, triggers, indexes and reporting views. |
| `CCMS_V5_reporting_queries.sql` | 35 practical SQL reports and audit queries demonstrating the questions the database can answer. |
| `CCMS_V5_DATABASE_DESIGN.md` | This design explanation, table catalogue, rules, and implementation notes. |

## 3. Main design improvements over the earlier project schema

### 3.1 Courts are modelled as forums

The earlier model used a single `COURT` table. V5 uses `FORUM` and `FORUM_TYPE`. A forum can represent a Supreme Court, High Court, District Court, subordinate court, Family Court, Commercial Court, Special Court, tribunal, commission, Lok Adalat, Gram Nyayalaya or another adjudicatory forum.

The list is configurable rather than hard-coded as a complete legal taxonomy. `FORUM_RELATIONSHIP` records appellate, administrative-supervision and other relationships separately. This matters because appellate relationships and administrative hierarchies are not necessarily identical.

Territorial jurisdiction and subject-matter jurisdiction are many-to-many relationships, stored separately in `FORUM_TERRITORIAL_JURISDICTION` and `FORUM_SUBJECT_JURISDICTION`.

### 3.2 A party's legal role belongs to a case

The old `PARTY.Party_Type` design could incorrectly imply that a person is always a plaintiff or always a defendant. V5 stores the person or organization in `PARTY`, and stores the role in `CASE_PARTY` using `CASE_PARTY_ROLE`.

Therefore, the same person can be a plaintiff in one case and a defendant, respondent, applicant, accused or another role in a different case.

### 3.3 Lawyer representation is historical

`LAWYER_PROFILE` stores the lawyer's identity and `LAWYER_REGISTRATION` stores bar registration details. `LAWYER_REPRESENTATION` links a lawyer to a particular party in a particular case, with appointment and end dates.

This supports multiple lawyers for one party, a lawyer representing different parties in different cases, and multiple representation periods over the lifetime of a case. It avoids assuming that one `(Lawyer_ID, Case_ID)` pair can have only one period.

### 3.4 Filing and petition are not restricted to one per case

`CASE_FILING` stores each submission. `PETITION_DETAIL` stores additional information when a filing is a petition. A case can have multiple petitions, applications, written statements, replies, affidavits and additional document filings.

A first filing may be captured before a formal case record has been created; `CASE_FILING.case_id` is therefore nullable. Once the matter is registered, the filing can be linked to its case.

### 3.5 Case history is stored as events

`CASE_FILE` does not store a separately editable current status. Status changes are recorded in `CASE_STATUS_HISTORY`, and `V_CASE_CURRENT_STATUS` exposes the latest status. A trigger creates the initial `FILED` status automatically when a case is created.

`CASE_STATUS_TRANSITION` defines permitted status transitions. A trigger rejects an unlisted status jump. Additional transitions can be configured after the applicable court workflow has been agreed.

Judge postings, bench assignments, lawyer representation, case transfers, filing reviews, document versions, evidence reviews and audit events also retain historical records rather than overwriting the earlier event.

### 3.6 A cause list is separate from a hearing

`CAUSE_LIST` identifies a list for a forum, date, session and version. `HEARING` stores the hearing itself. `CAUSE_LIST_ITEM` connects the two and stores `SEQUENCE_NUMBER`.

This correctly places the sequence number on the hearing's position in a particular cause list. A hearing can appear in a revised cause-list version without changing the hearing record.

### 3.7 Witness information is connected to a case and hearing

A witness is represented as a person/party with a `WITNESS` case role. `WITNESS_SUMMONS` records summons and service details for a particular case. `HEARING_WITNESS` records attendance and testimony for a particular hearing. Testimony is not stored as a permanent attribute of the witness.

### 3.8 Evidence has review and custody history

`EVIDENCE_ITEM` stores the evidence record. `EVIDENCE_REVIEW` stores decisions over time. `EVIDENCE_CUSTODY_EVENT` records receiving, transfer, storage, access, sealing and return events. Documents or files associated with evidence are linked through `EVIDENCE_DOCUMENT`.

### 3.9 Orders and judgments have different lifecycles

`COURT_ORDER` stores orders, directions and other formal court orders. `JUDGMENT` stores judgment-specific information and can link to a formal order. A case is not restricted to exactly one judgment. Interim, final, partial and corrected judgment records can exist over the case lifecycle.

### 3.10 Documents have versions

`DOCUMENT` stores logical document metadata. `DOCUMENT_VERSION` stores each uploaded version, storage key, filename, file type, size and checksum. `DOCUMENT_REVIEW` retains verification decisions. File bytes should be stored in protected storage, not directly in PostgreSQL.

### 3.11 Roles can be assigned in different scopes

A user can have multiple roles through `USER_ROLE_ASSIGNMENT`. An assignment can be global, forum-scoped or case-scoped. Permissions are described through `APP_ROLE`, `APP_PERMISSION` and `ROLE_PERMISSION`.

This supports the roles selected for the project: Platform Super Admin, Court Administrator/Registrar, Registry Clerk, Judge, Lawyer, Litigant, Public User and Auditor.

The application must still enforce case-level and document-level authorization. A public account must not gain access to sealed or restricted documents merely because it has a `CASE_READ` permission.

## 4. Table catalogue

The schema has 80 tables. They are grouped below by responsibility.

### A. Reference and configuration

| Table | Purpose |
|---|---|
| `FORUM_TYPE` | Configurable types of courts and adjudicatory forums. |
| `FORUM_RELATIONSHIP_TYPE` | Types of relationships between forums. |
| `JURISDICTION_AREA` | Country/state/district/sub-district/local-area hierarchy. |
| `SUBJECT_MATTER` | Configurable subject-matter categories. |
| `CASE_CATEGORY`, `CASE_TYPE` | Broad category and detailed case type. |
| `CASE_STATUS`, `CASE_STATUS_TRANSITION` | Case statuses and permitted transitions. |
| `CASE_PARTY_ROLE` | Petitioner, plaintiff, appellant, defendant, respondent, accused, witness, etc. |
| `CASE_RELATIONSHIP_TYPE` | Connected matter, appeal, revision, review, consolidation and related case types. |
| `FILING_TYPE`, `FILING_STATUS` | Filing categories and filing workflow statuses. |
| `EVIDENCE_TYPE` | Evidence categories. |
| `COURT_ORDER_TYPE` | Order categories. |
| `DOCUMENT_TYPE` | Document categories. |
| `FEE_TYPE` | Court fee categories. |
| `LEGAL_SPECIALIZATION` | Lawyer practice specializations. |

### B. Forum and court administration

| Table | Purpose |
|---|---|
| `FORUM` | Each court, tribunal, commission or other adjudicatory forum. |
| `FORUM_RELATIONSHIP` | Appellate and administrative relationships between forums. |
| `FORUM_TERRITORIAL_JURISDICTION` | Territorial jurisdiction over one or more areas. |
| `FORUM_SUBJECT_JURISDICTION` | Subject-matter jurisdiction. |
| `COURTROOM` | Rooms belonging to a forum. |
| `BENCH` | Benches within a forum. |
| `COURT_CALENDAR_EVENT` | Holidays, vacations, working days and special sittings. |

### C. People and court professionals

| Table | Purpose |
|---|---|
| `PERSON` | Shared personal identity data. |
| `ORGANIZATION` | Companies, government bodies, firms and other organizations. |
| `LAWYER_PROFILE`, `LAWYER_REGISTRATION` | Lawyer profiles and one or more bar registrations. |
| `LAWYER_SPECIALIZATION` | Many-to-many lawyer specialization and experience information. |
| `JUDGE_PROFILE` | Judge identity and career status. |
| `JUDGE_POSTING` | Historical judge postings to forums. |
| `JUDGE_BENCH_ASSIGNMENT` | Historical assignment of judges to benches. |
| `COURT_STAFF` | Court employee identity. |
| `STAFF_ASSIGNMENT` | Historical staff assignment to forums and duties. |

### D. Authentication and access control

| Table | Purpose |
|---|---|
| `USER_ACCOUNT` | Login account; stores a password hash, never a plain password. |
| `APP_ROLE` | Named user roles. |
| `APP_PERMISSION` | Fine-grained permissions. |
| `ROLE_PERMISSION` | Permissions attached to roles. |
| `USER_ROLE_ASSIGNMENT` | Multiple global, forum-level or case-level role assignments. |

### E. Case and parties

| Table | Purpose |
|---|---|
| `PARTY` | A person or organization participating in a case. |
| `CASE_FILE` | Main case record, CNR, title, type, originating and current forum. |
| `CASE_REGISTRATION` | Local case registration number history across forums. |
| `CASE_STATUS_HISTORY` | Every status change. |
| `CASE_PARTY` | Party's role and participation period in a particular case. |
| `LAWYER_REPRESENTATION` | Lawyer appointment and representation history for a case party. |
| `CASE_RELATIONSHIP` | Links connected, appealed, revised, reviewed or consolidated cases. |
| `CASE_TRANSFER` | Transfer history between forums; a trigger updates the current forum on the case. |

### F. Filing and registry

| Table | Purpose |
|---|---|
| `CASE_FILING` | Every petition, application, reply, written statement or other filing. |
| `PETITION_DETAIL` | Petition-specific information linked to a filing. |
| `FILING_REVIEW` | Scrutiny, verification and registration review events. |
| `FILING_DEFECT` | Defects, deadlines, cure status and resolution information. |

### G. Documents

| Table | Purpose |
|---|---|
| `DOCUMENT` | Logical document metadata, confidentiality and visibility. |
| `DOCUMENT_VERSION` | Immutable upload/version metadata. |
| `DOCUMENT_REVIEW` | Verification/rejection history for a document version. |
| `CASE_DOCUMENT`, `FILING_DOCUMENT` | Links documents to a case or filing. |

### H. Hearings and cause lists

| Table | Purpose |
|---|---|
| `CAUSE_LIST` | Daily/session cause-list metadata and versions. |
| `HEARING` | Scheduled and actual hearing information. |
| `CAUSE_LIST_ITEM` | Sequence and position of a hearing in one cause list. |
| `ADJOURNMENT_REQUEST` | Adjournment request, judicial decision and rescheduled hearing. |
| `HEARING_ATTENDANCE` | Attendance of a party or lawyer representation. |
| `WITNESS_SUMMONS` | Issue and service of witness summons. |
| `HEARING_WITNESS` | Witness attendance and hearing-specific testimony record. |

### I. Evidence

| Table | Purpose |
|---|---|
| `EVIDENCE_ITEM` | Evidence and exhibit metadata. |
| `EVIDENCE_REVIEW` | Judicial review and admission decisions over time. |
| `EVIDENCE_CUSTODY_EVENT` | Chain-of-custody event history. |
| `EVIDENCE_DOCUMENT` | Documents attached to evidence items. |

### J. Orders, judgments and legal references

| Table | Purpose |
|---|---|
| `COURT_ORDER` | Interim, procedural, final and other court orders. |
| `COURT_ORDER_JUDGE` | Judges associated with an order and their roles. |
| `JUDGMENT` | Judgment details, including finality and pronouncement date. |
| `ORDER_DOCUMENT` | Documents attached to an order. |
| `APPEAL_DETAIL` | Appellate case, originating case and challenged order. |
| `STATUTE`, `LEGAL_PROVISION` | Legal enactments and individual provisions. |
| `CASE_LEGAL_PROVISION` | Provisions linked to a case and the side/application context. |

### K. Fees, notifications and audit

| Table | Purpose |
|---|---|
| `CASE_FEE` | Fees assessed against a case or filing. |
| `PAYMENT` | Full or partial fee payment transactions. |
| `NOTIFICATION` | User notifications and their status. |
| `NOTIFICATION_DELIVERY_ATTEMPT` | Delivery retries and failure information. |
| `AUDIT_LOG` | Who changed what, when, from where and before/after state. |

## 5. Reporting views included in the schema

| View | What it provides |
|---|---|
| `V_CASE_CURRENT_STATUS` | Every case with its latest status and current forum. |
| `V_PENDING_CASE_DASHBOARD` | Pending-case age in days and age bucket. |
| `V_UPCOMING_HEARINGS` | Scheduled future hearings with case, forum, bench and room. |
| `V_CAUSE_LIST_DETAILS` | Ordered cause-list entries with case and hearing details. |
| `V_FORUM_CASE_BACKLOG` | Case backlog grouped by forum, case category and status. |
| `V_LAWYER_ACTIVE_CASE_LOAD` | Active case load and total cases ever represented. |
| `V_OPEN_FILING_DEFECTS` | Open defects and overdue indicator. |
| `V_EVIDENCE_REVIEW_QUEUE` | Evidence awaiting admission review. |
| `V_CASE_DISPOSAL_TIME` | Days from filing to first final judgment, when recorded. |
| `V_CASE_ADJOURNMENT_SUMMARY` | Hearing and adjournment counts per case. |
| `V_OUTSTANDING_CASE_FEES` | Remaining unpaid amount per case. |
| `V_JUDGE_UPCOMING_HEARING_LOAD` | Upcoming hearing count for each judge based on current bench assignment. |

The additional query file provides 35 examples for operational reporting, compliance checks and analytics.

## 6. Important business rules to enforce in the application

1. **Case creation:** Creating a `CASE_FILE` automatically records the initial `FILED` status. Further statuses must be inserted into `CASE_STATUS_HISTORY`; do not overwrite earlier history.
2. **Status changes:** The database trigger rejects a status transition not listed in `CASE_STATUS_TRANSITION`. The backend should show a clear message and require authorized users for sensitive transitions.
3. **Transfers:** Insert a `CASE_TRANSFER` only after a transfer has been approved and is effective. The trigger validates the source forum and updates `CASE_FILE.current_forum_id` to the receiving forum.
4. **Registration numbers:** A case may have a CNR and one or more local registration records. Validate the format and allocation rules used by the particular forum; do not generate official identifiers by guessing.
5. **Party roles:** Use `CASE_PARTY_ROLE`, not a global plaintiff/defendant attribute on `PARTY`.
6. **Representation:** A lawyer's authority must be valid for that party and case at the relevant date. Ended or withdrawn representation must remain in history.
7. **Scheduling:** Before committing a hearing, check the courtroom and all judges assigned to the bench for overlapping time slots. The included queries identify possible conflicts; the backend should prevent them transactionally.
8. **Cause lists:** Publish a cause list only after its entries and sequence numbers are validated. A later version should not erase the earlier published version.
9. **Filing defects:** Store the actual court-approved cure deadline. Do not assume a fixed seven-day period across all courts or filing types.
10. **Evidence:** Do not overwrite review or custody events. Add new review/custody records for every event.
11. **Orders and judgments:** An interim order does not automatically mean a case is disposed. A final status change should be supported by the relevant judicial record and authorized workflow.
12. **Documents:** Never expose `storage_key` or restricted file URLs to public users. Check the user's case and document permissions before serving a file.
13. **Payments:** A payment marked failed or refunded must not count as money successfully received.
14. **Audit:** Record security-sensitive actions, status changes, document access, transfers, order publication and permission changes. Avoid placing passwords, access tokens or unnecessary personal data in audit JSON.
15. **Deletion:** Legal records should normally be deactivated, superseded or corrected with an audit trail rather than physically deleted.

## 7. Important implementation notes

### Database setup

1. Create a new PostgreSQL database named `ccms_db` in pgAdmin or `psql`.
2. Open that database.
3. Execute all of `CCMS_V5_schema.sql`.
4. Execute `CCMS_V5_reporting_queries.sql` after adding test records.
5. Confirm that the lookup rows and all tables/views were created successfully.

This script is intended for a **fresh project database**. It does not drop or overwrite the old project database. Keep your previous SQL database as a backup until V5 has been tested.

### Lab 11 minimum implementation

For the Lab 11 CRUD demonstration, use `CASE_FILE` as the main table. The Streamlit form can use dropdowns for `CASE_TYPE`, `FORUM` and the creator account. The CRUD code must:

- connect using `psycopg2`;
- use `%s` placeholders for all user-supplied values;
- commit successful INSERT/UPDATE/DELETE operations;
- use a `WHERE` condition for UPDATE and DELETE;
- roll back when an operation fails;
- never display or commit database credentials to source control.

The complete project can be developed module by module after the basic connection and case CRUD have been demonstrated.

### Security and real-world deployment

This is a comprehensive academic/project schema, not a certified production court system. Before real deployment, the design needs review by people who understand the relevant court's procedure and applicable laws. A real deployment also needs hardened authentication, multi-factor authentication where appropriate, PostgreSQL row-level security or equivalent enforcement, encryption, backups and disaster recovery, secure file storage, monitoring, vulnerability testing, data-retention policy, privacy controls, official CNR/registry integration, digital-signature verification, payment integration and a formal access-control review.

The permission tables describe roles and capabilities; they do not automatically secure every SQL query. The Python service layer must enforce access rules, and sensitive installations should enforce them again at the database layer.

## 8. Decisions that can be refined later without redesigning the core

- Additional court, tribunal and commission types can be added to `FORUM_TYPE`.
- Additional case categories and case types can be added to `CASE_CATEGORY` and `CASE_TYPE`.
- State- and court-specific party roles can be added to `CASE_PARTY_ROLE`.
- More case statuses and transitions can be added after workflow approval.
- More filing types, document types, order types, evidence types and fee types can be added through their lookup tables.
- Different court-specific filing, limitation, holiday and fee rules can be stored in additional rule tables after the relevant rules are confirmed.
- APIs to official registries, e-filing portals, eCourts services, digital-signature services and payment providers can be added later. They are not assumed to exist in this schema.

---

**Recommended next step:** Load this schema into a separate PostgreSQL database, verify creation, then create a small realistic test dataset before asking Codex to build the full Streamlit application.
