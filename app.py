"""Court case registry interface for the coursework PostgreSQL schema."""
from datetime import date
from pathlib import Path

import pandas as pd
import psycopg
import streamlit as st

from auth.coursework_auth import verify_coursework_login
from auth.permissions import has_permission
from database.connection import get_connection, health_check
from repositories.coursework_case_repository import (
    archive_case, create_case, get_case, get_case_types, get_cases,
    get_courts, get_dashboard_summary, postgres_version, update_case,
)
from services.access_service import private_document, public_case_search, public_orders, set_case_public
from services.filing_service import submit_petition
from services.filing_review_service import pending_filings, record_scrutiny, resolve_defect
from services.scheduling_service import assign_case_to_bench, hearings_for_case, list_benches, record_proceedings, schedule_hearing
from services.judicial_service import create_judgment, create_order, pending_adjournments, public_cause_lists, publish_cause_list, request_adjournment, review_adjournment, set_judgment_public, set_order_public
from services.access_service import admin_users, create_user, profile_options, update_user_access
from services.liaison_service import liaison_history, record_liaison_update
from services.notification_service import queued_notifications, send_queued_emails
from services.fee_service import assess_fee, list_case_fees, record_fee_result
from services.lifecycle_service import TRANSITIONS, transition_case
from services.transfer_service import transfer_case

st.set_page_config(page_title="Court Case Management", page_icon="⚖️", layout="wide")
st.markdown("""<style>
.block-container{max-width:1420px;padding:2rem 2.2rem 3rem}
[data-testid="stMetric"]{background:#fff;padding:18px 20px;border:1px solid #e4e7ec;border-radius:14px;box-shadow:0 2px 8px rgba(16,24,40,.04)}
[data-testid="stMetricLabel"]{color:#475467!important;font-weight:600}
[data-testid="stMetricValue"]{color:#101828!important;font-weight:700}
section[data-testid="stSidebar"]{background:#f2f5fa;border-right:1px solid #e4e7ec}
.eyebrow{color:#667085;font-size:.94rem;margin-top:-.5rem;margin-bottom:1.2rem}
</style>""", unsafe_allow_html=True)


def show_error(exc: Exception) -> None:
    if isinstance(exc, psycopg.errors.UniqueViolation):
        st.error("A unique case reference already exists. Please retry the registration.")
    elif isinstance(exc, psycopg.errors.ForeignKeyViolation):
        st.error("The selected court or related record is not valid.")
    elif isinstance(exc, PermissionError):
        st.error(str(exc))
    elif isinstance(exc, ValueError):
        st.error(str(exc))
    else:
        st.error("The operation could not be completed. Check database connectivity and required migrations, then retry.")


connected, db_message = health_check()
if "user" not in st.session_state:
    st.title("⚖️ Court Case Management")
    access_mode = st.radio("Choose access", ["Sign in", "Public portal"], horizontal=True)
    if access_mode == "Public portal":
        if not connected:
            st.error(db_message)
            st.stop()
        st.markdown('<p class="eyebrow">Public case information · Published cause lists and orders only</p>', unsafe_allow_html=True)
        case_tab, cause_tab, order_tab = st.tabs(["Case search", "Published cause lists", "Public orders"])
        with case_tab:
            term = st.text_input("Search public cases by CUID, CNR, or title")
            st.dataframe(pd.DataFrame(public_case_search(term)), use_container_width=True, hide_index=True)
        with cause_tab:
            public_list=pd.DataFrame(public_cause_lists())
            st.dataframe(public_list, use_container_width=True, hide_index=True)
            if not public_list.empty:
                st.download_button("Download cause list CSV",public_list.to_csv(index=False),"public_cause_list.csv","text/csv")
        with order_tab:
            term = st.text_input("Filter public orders", key="public_order_search")
            orders=public_orders(term)
            st.dataframe(pd.DataFrame(orders), use_container_width=True, hide_index=True)
            for idx, order in enumerate(orders):
                st.download_button(
                    f"Download published {order['order_type']} #{order['order_id']}",
                    order["order_content"],
                    f"public_order_{order['order_type']}_{order['order_id']}.txt",
                    "text/plain",
                    key=f"public_order_{order['order_type']}_{order['order_id']}_{idx}"
                )
        st.stop()
    st.markdown('<p class="eyebrow">Secure court operations · PostgreSQL</p>', unsafe_allow_html=True)
    if not connected:
        st.error(db_message)
        st.stop()
    with st.form("sign_in"):
        username = st.text_input("Username")
        password = st.text_input("Password", type="password")
        submit = st.form_submit_button("Sign in", type="primary", use_container_width=True)
    if submit:
        try:
            account = verify_coursework_login(username, password)
            if account:
                st.session_state.user = account
                st.rerun()
            st.error("Sign-in failed. Check the username, password, or account status.")
        except Exception as exc:
            st.error("Unable to sign in. Check database setup and account status.")
    st.caption("Sign in with an active database account.")
    st.stop()

user = st.session_state.user
with st.sidebar:
    st.markdown("# ⚖️ Court operations")
    st.caption(f"{user['username']} · {user['role_name']}")
    if connected:
        st.success("Database connected")
        with st.expander("Database server"):
            try:
                st.code(postgres_version())
            except Exception as exc:
                st.error(str(exc))
    else:
        st.error(db_message)
    pages = ["Overview"]
    if has_permission(user,"CASE_READ"):
        pages.append("Case registry")
    for permission_code, page_name in [
        ("FILING_SUBMIT","E-Filing"),("FILING_REVIEW","Registry scrutiny"),
        ("HEARING_MANAGE","Hearings and cause lists"),("ORDER_MANAGE","Judicial work"),
        ("POLICE_LIAISON","Agency liaison"),("USER_ADMIN","User administration")]:
        if has_permission(user,permission_code):
            pages.append(page_name)
    if has_permission(user,"NOTIFICATION_MANAGE"):
        pages.append("Notifications")
    if has_permission(user,"ADJOURNMENT_REQUEST"):
        pages.append("Adjournment requests")
    if has_permission(user,"CASE_STATUS_MANAGE"):
        pages.append("Case lifecycle")
    if has_permission(user,"CASE_PUBLISH") and "Judicial work" not in pages:
        pages.append("Judicial work")
    page = st.radio("Workspace", pages, label_visibility="collapsed")
    if st.button("Sign out", use_container_width=True):
        try:
            with get_connection() as conn:
                conn.execute("INSERT INTO auth_event_log(username,user_id,event_type) VALUES (%s,%s,'LOGOUT')",(user["username"],user["user_id"]))
        except Exception:
            pass
        st.session_state.clear()
        st.rerun()

st.title("Court Case Management")
st.markdown('<p class="eyebrow">Case records · Filing review · Hearings · Audit trail</p>', unsafe_allow_html=True)
if not connected:
    st.error(db_message)
    st.stop()

scoped_roles={"presiding judge","court clerk","court master / bench clerk","advocate","advocate / legal counsel","police & prison liaison"}
try:
    summary = get_dashboard_summary(user=user) if page=="Overview" and user["role_name"].lower() not in scoped_roles else None
except Exception as exc:
    st.error("Could not load the dashboard. Confirm that the additive functionality migration has been applied.")
    st.stop()

if page == "Overview":
    st.subheader("Operations overview")
    st.caption(f"Live database summary · {date.today():%d %B %Y}")
    if user["role_name"].lower() in scoped_roles:
        scoped_cases=get_cases(limit=500,user=user)
        ids=[r["case_id"] for r in scoped_cases]
        if not ids:
            st.info("No cases are currently associated with your account scope.")
            st.stop()
        with get_connection() as conn:
            stats=conn.execute("""SELECT
                (SELECT COUNT(*) FROM hearing WHERE case_id=ANY(%s) AND hearing_date=CURRENT_DATE) AS today_hearings,
                (SELECT COUNT(*) FROM hearing WHERE case_id=ANY(%s) AND hearing_date>=CURRENT_DATE) AS upcoming_hearings,
                (SELECT COUNT(*) FROM filing_defect WHERE case_id=ANY(%s) AND lower(cure_status) NOT IN ('cured','resolved')) AS open_defects,
                (SELECT COUNT(*) FROM petition WHERE case_id=ANY(%s) AND filing_status='PENDING_SCRUTINY') AS pending_scrutiny""",(ids,ids,ids,ids)).fetchone()
            next_hearings=conn.execute("""SELECT c.cnr,c.case_title,h.hearing_date,h.start_time,h.hearing_purpose,cr.room_number
                FROM hearing h JOIN court_case c USING(case_id) JOIN courtroom cr USING(room_id)
                WHERE h.case_id=ANY(%s) AND h.hearing_date>=CURRENT_DATE ORDER BY h.hearing_date,h.start_time LIMIT 12""",(ids,)).fetchall()
        cols=st.columns(4)
        for col,label,value in zip(cols,["Assigned cases","Hearings today","Upcoming hearings","Open defects"],[len(scoped_cases),stats["today_hearings"],stats["upcoming_hearings"],stats["open_defects"]]):
            col.metric(label,value)
        st.markdown("**Your upcoming hearings**")
        st.dataframe(pd.DataFrame(next_hearings),use_container_width=True,hide_index=True)
        st.markdown("**Cases in your authorized scope**")
        st.dataframe(pd.DataFrame(scoped_cases),use_container_width=True,hide_index=True)
        st.stop()
    metrics = st.columns(5)
    for col, title, key in zip(metrics,
            ["Registered cases", "Pending scrutiny", "Disposed", "Filed this month", "Hearings today"],
            ["total_cases", "pending_scrutiny", "disposed_cases", "filings_this_month", "today_hearings"]):
        if key == "filings_this_month":
            with get_connection() as conn:
                value = conn.execute("SELECT COUNT(*) AS n FROM court_case WHERE filing_date >= date_trunc('month',CURRENT_DATE) AND archived_at IS NULL").fetchone()["n"]
        else:
            value = summary[key]
        col.metric(title, value)
    extra = st.columns(4)
    for col,title,key in zip(extra,["Pending cases","Upcoming hearings","Open defects","Registered parties"],["cases_under_hearing","upcoming_hearings","open_defects","parties"]):
        col.metric(title,summary[key])
    left, right = st.columns([1.2, 1])
    with left:
        st.subheader("Cases by type")
        with get_connection() as conn:
            rows = conn.execute("SELECT case_type,COUNT(*) AS case_count FROM court_case WHERE archived_at IS NULL GROUP BY case_type ORDER BY case_count DESC").fetchall()
        if rows:
            st.bar_chart(pd.DataFrame(rows).set_index("case_type"), color="#175CD3")
        else:
            st.info("No active cases found.")
    with right:
        st.subheader("Case volume by court")
        with get_connection() as conn:
            rows = conn.execute("SELECT co.jurisdiction_area AS court,COUNT(*) AS case_count FROM court_case c JOIN court co USING(court_id) WHERE c.archived_at IS NULL GROUP BY co.jurisdiction_area ORDER BY case_count DESC").fetchall()
        st.dataframe(pd.DataFrame(rows), use_container_width=True, hide_index=True)
    st.subheader("Cases by current status")
    with get_connection() as conn:
        rows = conn.execute("""SELECT COALESCE((SELECT new_status FROM case_status_history h WHERE h.case_id=c.case_id ORDER BY transition_timestamp DESC LIMIT 1),'Unclassified') AS status,COUNT(*) AS cases
            FROM court_case c WHERE c.archived_at IS NULL GROUP BY status ORDER BY cases DESC""").fetchall()
        recent = conn.execute("SELECT case_id,cuid,cnr,case_title,case_type,filing_date FROM court_case WHERE archived_at IS NULL ORDER BY filing_date DESC,case_id DESC LIMIT 8").fetchall()
        hearings = conn.execute("""SELECT c.cnr,c.case_title,h.hearing_date,h.start_time,h.hearing_purpose,cr.room_number
            FROM hearing h JOIN court_case c USING(case_id) JOIN courtroom cr USING(room_id)
            WHERE h.hearing_date>=CURRENT_DATE AND c.archived_at IS NULL ORDER BY h.hearing_date,h.start_time LIMIT 8""").fetchall()
    if rows:
        st.bar_chart(pd.DataFrame(rows).set_index("status"),color="#1570EF")
    with get_connection() as conn:
        filing_trend=conn.execute("""SELECT date_trunc('month',filing_date)::date AS month,COUNT(*) AS filings
            FROM court_case WHERE filing_date>=CURRENT_DATE-INTERVAL '11 months' GROUP BY month ORDER BY month""").fetchall()
        hearing_trend=conn.execute("""SELECT date_trunc('month',hearing_date)::date AS month,COUNT(*) AS hearings
            FROM hearing WHERE hearing_date>=CURRENT_DATE-INTERVAL '11 months' GROUP BY month ORDER BY month""").fetchall()
        recent_orders=conn.execute("""SELECT o.order_type,c.cnr,c.case_title,o.order_id FROM court_order o JOIN court_case c USING(case_id)
            WHERE c.archived_at IS NULL ORDER BY o.order_id DESC LIMIT 6""").fetchall()
        pending=conn.execute("""SELECT p.subject,c.cnr,c.case_title,p.submitted_at FROM petition p JOIN court_case c USING(case_id)
            WHERE p.filing_status='PENDING_SCRUTINY' AND c.archived_at IS NULL ORDER BY p.submitted_at LIMIT 6""").fetchall()
        activity=conn.execute("""SELECT action_performed,event_type,entity_name,\"timestamp\" FROM audit_log
            ORDER BY \"timestamp\" DESC LIMIT 8""").fetchall()
    chart1,chart2=st.columns(2)
    with chart1:
        st.markdown("**Monthly filings**")
        if filing_trend:
            st.line_chart(pd.DataFrame(filing_trend).set_index("month"),color="#175CD3")
    with chart2:
        st.markdown("**Monthly hearings**")
        if hearing_trend:
            st.line_chart(pd.DataFrame(hearing_trend).set_index("month"),color="#039855")
    a,b=st.columns(2)
    with a:
        st.markdown("**Recently filed cases**")
        st.dataframe(pd.DataFrame(recent),use_container_width=True,hide_index=True)
    with b:
        st.markdown("**Upcoming hearings**")
        st.dataframe(pd.DataFrame(hearings),use_container_width=True,hide_index=True)
    a,b=st.columns(2)
    with a:
        st.markdown("**Pending scrutiny**")
        st.dataframe(pd.DataFrame(pending),use_container_width=True,hide_index=True)
        st.markdown("**Recent orders**")
        st.dataframe(pd.DataFrame(recent_orders),use_container_width=True,hide_index=True)
    with b:
        st.markdown("**Recent activity**")
        st.dataframe(pd.DataFrame(activity),use_container_width=True,hide_index=True)
    st.caption("Dashboard figures are queried from the connected PostgreSQL database.")
elif page == "Case registry":
    st.subheader("Case registry")
    can_create = has_permission(user, "CASE_CREATE")
    can_update = has_permission(user, "CASE_UPDATE")
    can_archive = has_permission(user, "CASE_ARCHIVE")
    can_transfer = has_permission(user,"CASE_TRANSFER")
    tab_labels = (["Register"] if can_create else []) + ["Search and view"] + (["Update"] if can_update else []) + (["Transfer"] if can_transfer else []) + (["Archive"] if can_archive else [])
    tabs = iter(st.tabs(tab_labels))
    register_tab = next(tabs) if can_create else None
    browse_tab = next(tabs)
    update_tab = next(tabs) if can_update else None
    transfer_tab = next(tabs) if can_transfer else None
    archive_tab = next(tabs) if can_archive else None
    courts = get_courts()
    court_names = {r["court_id"]: f"{r['jurisdiction_area']} · {r['physical_address']}" for r in courts}
    case_types = get_case_types() or ["Civil", "Criminal", "Constitutional", "Commercial"]

    if register_tab:
        with register_tab:
            st.caption("CUID and CNR are assigned automatically when the case is registered.")
            with st.form("create_case", clear_on_submit=True):
                title = st.text_input("Case title")
                case_type = st.selectbox("Case type", case_types)
                filing_date = st.date_input("Filing date", value=date.today())
                court_id = st.selectbox("Court", list(court_names), format_func=lambda x: court_names[x])
                submitted = st.form_submit_button("Register case", type="primary")
            if submitted:
                if not title.strip() or filing_date > date.today():
                    st.error("Enter a case title and a filing date that is not in the future.")
                else:
                    try:
                        case_id = create_case(case_title=title, case_type=case_type, filing_date=filing_date,
                                              court_id=court_id, user_id=user["user_id"])
                        st.success(f"Case registered · internal ID {case_id}. References were generated and the action was audited.")
                    except Exception as exc:
                        show_error(exc)

    with browse_tab:
        search = st.text_input("Search by CUID, CNR, case title, party, type, or court")
        rows = get_cases(search, limit=200, user=user)
        st.dataframe(pd.DataFrame(rows), use_container_width=True, hide_index=True)
        st.caption(f"{len(rows)} matching record(s), up to 200.")
        if rows:
            chosen = st.selectbox("View case history", rows, format_func=lambda r: f"{r['cnr']} · {r['case_title']}")
            details = get_case(chosen["case_id"], user=user)
            if details:
                for key in ["status_history", "parties", "lawyers", "filings", "hearings", "attendance", "adjournments", "transfers", "evidence", "orders", "judgments", "documents", "audit"]:
                    st.markdown(f"**{key.replace('_',' ').title()}**")
                    related=details.pop(key)
                    st.dataframe(pd.DataFrame(related), use_container_width=True, hide_index=True)
                    if key=="documents":
                        for doc in related:
                            try:
                                downloadable=private_document(doc["document_id"],user=user)
                                if downloadable:
                                    st.download_button(f"Download {downloadable[0]}",data=downloadable[1],file_name=Path(downloadable[0]).name,mime="application/pdf",key=f"download_{doc['document_id']}")
                            except Exception:
                                pass
                st.json(details)

    if update_tab:
        with update_tab:
            rows = get_cases(limit=500, user=user)
            if rows:
                chosen = st.selectbox("Select case", rows, format_func=lambda r: f"{r['cnr']} · {r['case_title']}", key="update_select")
                current = get_case(chosen["case_id"], user=user)
                with st.form("update_case"):
                    title = st.text_input("Case title", value=current["case_title"])
                    idx = case_types.index(current["case_type"]) if current["case_type"] in case_types else 0
                    case_type = st.selectbox("Case type", case_types, index=idx)
                    filing_date = st.date_input("Filing date", value=current["filing_date"])
                    court_id = st.selectbox("Court", list(court_names), index=list(court_names).index(current["court_id"]), format_func=lambda x: court_names[x])
                    save = st.form_submit_button("Save changes", type="primary")
                if save:
                    try:
                        count = update_case(chosen["case_id"], case_title=title, case_type=case_type,
                                            filing_date=filing_date, court_id=court_id, user_id=user["user_id"])
                        st.success(f"Updated {count} case record(s).")
                    except Exception as exc:
                        show_error(exc)
            else:
                st.info("No cases are available to update.")

    if transfer_tab:
        with transfer_tab:
            rows=get_cases(limit=500,user=user)
            if rows:
                chosen=st.selectbox("Case to transfer",rows,format_func=lambda r:f"{r['cnr']} · {r['case_title']}",key="transfer_select")
                destinations=[r for r in courts if r["court_id"]!=chosen["court_id"]]
                with st.form("transfer_case"):
                    destination=st.selectbox("Destination court",destinations,format_func=lambda r:f"{r['jurisdiction_area']} · {r['physical_address']}") if destinations else None
                    reason=st.text_area("Transfer reason")
                    transferred=st.form_submit_button("Transfer case",type="primary",disabled=not destinations)
                if transferred and destination:
                    try:
                        transfer_case(user=user,case_id=chosen["case_id"],to_court_id=destination["court_id"],reason=reason)
                        st.success("Case transfer recorded. Upcoming hearings must be rescheduled before transfer.")
                    except Exception as exc:
                        show_error(exc)
            else:
                st.info("No active cases are available to transfer.")

    if archive_tab:
        with archive_tab:
            rows = get_cases(limit=500, user=user)
            if rows:
                chosen = st.selectbox("Select case", rows, format_func=lambda r: f"{r['cnr']} · {r['case_title']}", key="archive_select")
                st.info("Archiving preserves the case, linked records, and audit history.")
                with st.form("archive_case"):
                    reason = st.text_input("Reason")
                    confirm = st.checkbox("Confirm archive")
                    archive = st.form_submit_button("Archive", type="primary")
                if archive:
                    if not confirm or not reason.strip():
                        st.error("Confirm the action and enter a reason.")
                    else:
                        try:
                            archive_case(chosen["case_id"], reason=reason, user_id=user["user_id"])
                            st.success("Case archived. Existing records remain preserved.")
                        except Exception as exc:
                            show_error(exc)
            else:
                st.info("No active cases are available to archive.")

elif page == "E-Filing":
    st.subheader("Electronic petition filing")
    st.caption("Submissions and their parties, representation, petition, document, status, and audit records are committed together.")
    with get_connection() as conn:
        advocate=conn.execute("SELECT full_name,bar_registration_number,phone,email FROM lawyer WHERE lawyer_id=%s",(user.get("lawyer_id") or -1,)).fetchone()
    if advocate:
        st.info(f"Filing as {advocate['full_name']} · Bar registration {advocate['bar_registration_number']}")
    else:
        st.warning("Ask an administrator to link this account to an advocate profile before filing.")
    filing_types=get_case_types() or ["Civil","Criminal","Constitutional","Commercial"]
    with st.form("e_filing", clear_on_submit=True):
        title = st.text_input("Case title")
        case_type = st.selectbox("Case type",filing_types)
        courts = get_courts()
        court_map = {r["court_id"]: r["jurisdiction_area"] for r in courts}
        court_id = st.selectbox("Court", list(court_map), format_func=lambda x:court_map[x])
        filing_date = st.date_input("Filing date", value=date.today())
        jurisdiction=st.text_input("Jurisdiction / venue details")
        valuation=st.text_input("Monetary valuation (optional)")
        description = st.text_area("Petition summary / jurisdiction details")
        a,b=st.columns(2)
        with a:
            petitioner={"name":st.text_input("Petitioner name"),"phone":st.text_input("Petitioner phone"),"address":st.text_input("Petitioner address")}
        with b:
            respondent={"name":st.text_input("Respondent name"),"phone":st.text_input("Respondent phone"),"address":st.text_input("Respondent address")}
        petition_pdf = st.file_uploader("Signed petition PDF",type=["pdf"],key="petition_pdf")
        supporting_pdfs = st.file_uploader("Supporting PDFs",type=["pdf"],accept_multiple_files=True,key="supporting_pdfs")
        submitted=st.form_submit_button("Submit petition",type="primary")
    if submitted:
        if not petition_pdf:
            st.error("Attach the petition PDF.")
        else:
            try:
                uploads=[(petition_pdf.name,petition_pdf.getvalue(),petition_pdf.type or "application/pdf")]
                uploads.extend((item.name,item.getvalue(),item.type or "application/pdf") for item in supporting_pdfs)
                case_id,cuid,cnr=submit_petition(user=user,title=title,case_type=case_type,court_id=court_id,
                    filing_date=filing_date,description=description,petitioner=petitioner,respondent=respondent,
                    jurisdiction=jurisdiction,monetary_valuation=valuation,uploads=uploads)
                st.success(f"Filing received · {cuid} · {cnr} · case record {case_id}. {len(uploads)} private document(s) stored; status: pending registry scrutiny.")
            except Exception as exc:
                show_error(exc)

elif page == "Registry scrutiny":
    st.subheader("Registry scrutiny")
    rows=pending_filings(user=user)
    if rows:
        selected=st.selectbox("Pending petition",rows,format_func=lambda r:f"{r['cnr']} · {r['subject']} · {r['lawyer_name']}")
        with st.form("scrutiny"):
            decision=st.selectbox("Decision",["Approve","Return with defect"])
            remarks=st.text_area("Scrutiny notes")
            defect=st.text_area("Defect description (required when returning)")
            save=st.form_submit_button("Record scrutiny",type="primary")
        if save:
            try:
                defect_id=record_scrutiny(user=user,petition_id=selected["petition_id"],decision="APPROVE" if decision=="Approve" else "DEFECT",remarks=remarks,defect_description=defect)
                st.success("Filing approved." if defect_id is None else f"Filing returned. Defect #{defect_id} has a seven calendar day cure deadline; an email notification is queued.")
            except Exception as exc:
                show_error(exc)
    else:
        st.info("No petitions are waiting for scrutiny.")
    st.markdown("#### Open filing defects")
    with get_connection() as conn:
        defects=conn.execute("""SELECT fd.defect_id,fd.defect_description,fd.cure_deadline,fd.cure_status,c.cnr,c.case_title
            FROM filing_defect fd LEFT JOIN court_case c USING(case_id) WHERE lower(fd.cure_status) NOT IN ('cured','resolved') ORDER BY fd.cure_deadline""").fetchall()
    if defects:
        st.dataframe(pd.DataFrame(defects),use_container_width=True,hide_index=True)
        defect=st.selectbox("Defect to resolve",defects,format_func=lambda r:f"#{r['defect_id']} · {r['cnr'] or 'Unlinked'} · due {r['cure_deadline']}")
        with st.form("resolve_defect"):
            notes=st.text_input("Resolution notes")
            resolved=st.form_submit_button("Mark cured")
        if resolved:
            try:
                resolve_defect(user=user,defect_id=defect["defect_id"],remarks=notes)
                st.success("Defect marked cured and filing returned to scrutiny queue.")
            except Exception as exc:
                show_error(exc)
    else:
        st.info("No open defects.")
    if has_permission(user,"FEE_MANAGE"):
        st.markdown("#### Fee assessments")
        fee_cases=get_cases(limit=500,user=user)
        if fee_cases:
            fee_case=st.selectbox("Case for fee assessment",fee_cases,format_func=lambda r:f"{r['cnr']} · {r['case_title']}",key="fee_case")
            fee_rows=list_case_fees(user=user,case_id=fee_case["case_id"])
            st.dataframe(pd.DataFrame(fee_rows),use_container_width=True,hide_index=True)
            with st.form("assess_fee"):
                amount=st.text_input("Assessed amount")
                currency=st.text_input("Currency",value="INR",max_chars=3)
                note=st.text_input("Assessment basis / note")
                assessed=st.form_submit_button("Record fee assessment")
            if assessed:
                try:
                    fee_id=assess_fee(user=user,case_id=fee_case["case_id"],petition_id=None,amount=amount,currency=currency,note=note)
                    st.success(f"Fee assessment #{fee_id} recorded as due.")
                except Exception as exc:
                    show_error(exc)
            due=[r for r in fee_rows if r["status"]=="DUE"]
            if due:
                fee=st.selectbox("Due fee",due,format_func=lambda r:f"#{r['fee_id']} · {r['amount']} {r['currency']}")
                result=st.selectbox("Record result",["PAID","WAIVED"])
                reference=st.text_input("Receipt / waiver reference")
                if st.button("Save fee result"):
                    try:
                        record_fee_result(user=user,fee_id=fee["fee_id"],status=result,reference=reference)
                        st.success("Fee result recorded and audited.")
                    except Exception as exc:
                        show_error(exc)

elif page == "Hearings and cause lists":
    st.subheader("Scheduling and courtroom work")
    case_rows=get_cases(limit=500,user=user)
    if not case_rows:
        st.info("No cases in your authorized scope.")
    else:
        selected=st.selectbox("Case",case_rows,format_func=lambda r:f"{r['cnr']} · {r['case_title']}")
        case_id=selected["case_id"]
        sched_tab,record_tab,cause_tab=st.tabs(["Schedule hearing","Proceedings and attendance","Cause lists"])
        with sched_tab:
            if has_permission(user,"HEARING_MANAGE",case_id=case_id):
                with get_connection() as conn:
                    rooms=conn.execute("SELECT room_id,room_number FROM courtroom WHERE court_id=%s ORDER BY room_number",(selected["court_id"],)).fetchall()
                benches=list_benches()
                with st.form("schedule_hearing"):
                    day=st.date_input("Hearing date",value=date.today())
                    start=st.time_input("Start time",value=__import__("datetime").time(10,0))
                    finish=st.time_input("End time",value=__import__("datetime").time(10,30))
                    room_id=st.selectbox("Courtroom",rooms,format_func=lambda r:r["room_number"])["room_id"] if rooms else None
                    bench_id=st.selectbox("Bench",benches,format_func=lambda r:f"{r['bench_name']} · {r['bench_type']}")["bench_id"] if benches else None
                    purpose=st.text_input("Hearing purpose")
                    session=st.selectbox("Cause list session",["Morning","Afternoon","Special"])
                    schedule=st.form_submit_button("Schedule hearing",type="primary",disabled=not rooms or not benches)
                if schedule:
                    try:
                        hearing_id=schedule_hearing(user=user,case_id=case_id,hearing_date=day,start_time=start,end_time=finish,room_id=room_id,bench_id=bench_id,purpose=purpose,session_name=session)
                        st.success(f"Hearing scheduled · ID {hearing_id}. It was added to a draft cause list.")
                    except Exception as exc:
                        show_error(exc)
            else:
                st.info("Your role cannot schedule hearings for this case.")
            if has_permission(user,"BENCH_ASSIGN",case_id=case_id):
                benches=list_benches()
                with st.form("assign_bench"):
                    bench_id=st.selectbox("Assign case to bench",benches,format_func=lambda r:r["bench_name"])["bench_id"] if benches else None
                    notes=st.text_input("Assignment notes")
                    assigned=st.form_submit_button("Assign bench",disabled=not benches)
                if assigned:
                    try:
                        assign_case_to_bench(user=user,case_id=case_id,bench_id=bench_id,notes=notes)
                        st.success("Bench assignment saved to the assignment history.")
                    except Exception as exc:
                        show_error(exc)
        with record_tab:
            hearings=hearings_for_case(case_id,user=user)
            if hearings and has_permission(user,"PROCEEDING_RECORD",case_id=case_id):
                hearing=st.selectbox("Hearing",hearings,format_func=lambda r:f"{r['hearing_date']} {r['start_time']} · {r['hearing_purpose']}")
                with get_connection() as conn:
                    parties=conn.execute("SELECT p.party_id,p.party_name FROM case_party cp JOIN party p USING(party_id) WHERE cp.case_id=%s ORDER BY p.party_name",(case_id,)).fetchall()
                    lawyers=conn.execute("SELECT l.lawyer_id,l.full_name FROM lawyer_case lc JOIN lawyer l USING(lawyer_id) WHERE lc.case_id=%s ORDER BY l.full_name",(case_id,)).fetchall()
                with st.form("record_proceedings"):
                    summary=st.text_area("Proceedings summary")
                    outcome=st.text_area("Outcome")
                    next_date=st.date_input("Next hearing date (select today if none)",value=date.today())
                    attendance_type=st.selectbox("Record attendance for",["None","Party","Lawyer"])
                    attendee_party=st.selectbox("Party",[None]+parties,format_func=lambda r:"Select party" if r is None else r["party_name"],disabled=attendance_type!="Party")
                    attendee_lawyer=st.selectbox("Lawyer",[None]+lawyers,format_func=lambda r:"Select lawyer" if r is None else r["full_name"],disabled=attendance_type!="Lawyer")
                    attendance_status=st.selectbox("Attendance",["PRESENT","ABSENT","EXCUSED","REMOTE","UNKNOWN"])
                    record=st.form_submit_button("Save proceedings",type="primary")
                if record:
                    try:
                        attendance=[]
                        if attendance_type=="Party" and attendee_party:
                            attendance.append({"party_id":attendee_party["party_id"],"status":attendance_status})
                        elif attendance_type=="Lawyer" and attendee_lawyer:
                            attendance.append({"lawyer_id":attendee_lawyer["lawyer_id"],"status":attendance_status})
                        record_proceedings(user=user,hearing_id=hearing["hearing_id"],summary=summary,outcome=outcome,next_date=None if next_date==date.today() else next_date,attendance=attendance)
                        st.success("Proceedings, outcome, and selected attendance were saved.")
                    except Exception as exc:
                        show_error(exc)
                st.dataframe(pd.DataFrame(hearings),use_container_width=True,hide_index=True)
            else:
                st.info("No hearings are available, or your role cannot record proceedings.")
        with cause_tab:
            with get_connection() as conn:
                cause_rows=conn.execute("""SELECT cl.cause_list_id,cl.cause_date,cl.session_name,cl.publication_status,COUNT(h.hearing_id) AS matters
                    FROM cause_list cl JOIN hearing h USING(cause_list_id) WHERE h.case_id=%s GROUP BY cl.cause_list_id ORDER BY cl.cause_date DESC""",(case_id,)).fetchall()
            if cause_rows:
                cl=st.selectbox("Draft/published cause list",cause_rows,format_func=lambda r:f"{r['cause_date']} · {r['session_name']} · {r['publication_status']} · {r['matters']} matters")
                if has_permission(user,"HEARING_MANAGE",case_id=case_id) and st.button("Publish cause list"):
                    try:
                        publish_cause_list(user=user,cause_list_id=cl["cause_list_id"])
                        st.success("Cause list is published for the public portal.")
                    except Exception as exc:
                        show_error(exc)
            else:
                st.info("No cause list exists for this case yet.")

elif page == "Judicial work":
    st.subheader("Judicial work")
    rows=get_cases(limit=500,user=user)
    if rows:
        chosen=st.selectbox("Assigned case",rows,format_func=lambda r:f"{r['cnr']} · {r['case_title']}")
        case_id=chosen["case_id"]
        order_tab,judgment_tab,publish_tab,adjourn_tab=st.tabs(["Orders","Judgment","Public access","Adjournments"])
        with order_tab:
            hearings=hearings_for_case(case_id,user=user)
            with st.form("create_order"):
                order_type=st.selectbox("Order type",["Interim order","Procedural order","Bail order","Final order"])
                hearing_id=st.selectbox("Related hearing",hearings,format_func=lambda r:f"{r['hearing_date']} · {r['hearing_purpose']}")["hearing_id"] if hearings else None
                content=st.text_area("Order content")
                submit=st.form_submit_button("Save unsigned order",disabled=not hearings)
            if submit:
                try:
                    order_id=create_order(user=user,case_id=case_id,hearing_id=hearing_id,order_type=order_type,content=content)
                    st.success(f"Unsigned order draft #{order_id} saved. PKI signing is not configured.")
                except Exception as exc:
                    show_error(exc)
            with get_connection() as conn:
                orders=conn.execute("SELECT order_id,order_type,order_content,digital_signature_hash,is_public FROM court_order WHERE case_id=%s ORDER BY order_id DESC",(case_id,)).fetchall()
                judgments=conn.execute("SELECT judgment_id,pronouncement_date,verdict_text,digital_signature_hash,is_public FROM judgment WHERE case_id=%s ORDER BY pronouncement_date DESC",(case_id,)).fetchall()
            st.dataframe(pd.DataFrame(orders),use_container_width=True,hide_index=True)
        with judgment_tab:
            with st.form("create_judgment"):
                pronouncement=date.today()
                verdict=st.text_area("Judgment / verdict text")
                saved=st.form_submit_button("Save unsigned judgment")
            if saved:
                try:
                    judgment_id=create_judgment(user=user,case_id=case_id,pronouncement_date=pronouncement,verdict=verdict)
                    st.success(f"Unsigned judgment #{judgment_id} saved. PKI signing is not configured.")
                except Exception as exc:
                    show_error(exc)
        with publish_tab:
            if has_permission(user,"CASE_PUBLISH",case_id=case_id):
                publish=st.checkbox("Make this non-confidential case visible in public search",value=bool(chosen.get("public_access",False)))
                if st.button("Save public visibility"):
                    try:
                        set_case_public(user=user,case_id=case_id,publish=publish)
                        st.success("Public visibility updated and audited.")
                    except Exception as exc:
                        show_error(exc)
                if orders:
                    order=st.selectbox("Order to publish",orders,format_func=lambda r:f"#{r['order_id']} · {r['order_type']}")
                    is_public=st.checkbox("Publish selected order",value=order["is_public"])
                    if st.button("Save order visibility"):
                        try:
                            set_order_public(user=user,order_id=order["order_id"],publish=is_public)
                            st.success("Order visibility updated.")
                        except Exception as exc:
                            show_error(exc)
                if judgments:
                    judgment=st.selectbox("Judgment to publish",judgments,format_func=lambda r:f"#{r['judgment_id']} · {r['pronouncement_date']}")
                    judgment_public=st.checkbox("Publish selected judgment",value=judgment["is_public"])
                    if st.button("Save judgment visibility"):
                        try:
                            set_judgment_public(user=user,judgment_id=judgment["judgment_id"],publish=judgment_public)
                            st.success("Judgment visibility updated.")
                        except Exception as exc:
                            show_error(exc)
            else:
                st.info("Only authorized judicial users can change public visibility.")
        with adjourn_tab:
            if user.get("judge_id") and has_permission(user,"ORDER_MANAGE",case_id=case_id):
                try:
                    pending=pending_adjournments(user=user)
                except Exception:
                    pending=[]
                if pending:
                    item=st.selectbox("Request for review",pending,format_func=lambda r:f"#{r['adjournment_id']} · {r['cnr']} · {r['reason']}")
                    notes=st.text_input("Review notes")
                    left,right=st.columns(2)
                    if left.button("Approve adjournment"):
                        try:
                            review_adjournment(user=user,adjournment_id=item["adjournment_id"],approve=True,remarks=notes)
                            st.success("Adjournment approved; the hearing was rescheduled.")
                        except Exception as exc:
                            show_error(exc)
                    if right.button("Reject adjournment"):
                        try:
                            review_adjournment(user=user,adjournment_id=item["adjournment_id"],approve=False,remarks=notes)
                            st.success("Adjournment rejected.")
                        except Exception as exc:
                            show_error(exc)
            else:
                st.info("Judicial review is available only to the assigned judge.")
    else:
        st.info("No assigned cases are in your authorized scope.")

elif page == "Case lifecycle":
    st.subheader("Case lifecycle")
    rows=get_cases(limit=500,user=user)
    if rows:
        chosen=st.selectbox("Case",rows,format_func=lambda r:f"{r['cnr']} · {r['case_title']} · {r['current_status'] or 'Unclassified'}")
        current=chosen["current_status"] or "Filed"
        options=sorted(TRANSITIONS.get(current,set()))
        if options:
            with st.form("case_transition"):
                new_status=st.selectbox("New status",options)
                remarks=st.text_area("Transition remarks")
                saved=st.form_submit_button("Record transition",type="primary")
            if saved:
                try:
                    previous=transition_case(user=user,case_id=chosen["case_id"],new_status=new_status,remarks=remarks)
                    st.success(f"Status changed from {previous} to {new_status}.")
                except Exception as exc:
                    show_error(exc)
        else:
            st.info(f"No further transition is allowed from {current}. Archive closed/disposed cases in the registry.")
        details=get_case(chosen["case_id"],user=user)
        st.markdown("**Lifecycle timeline**")
        st.dataframe(pd.DataFrame(details["status_history"]),use_container_width=True,hide_index=True)
    else:
        st.info("No cases are linked to your account.")

elif page == "Adjournment requests":
    st.subheader("Adjournment requests")
    rows=get_cases(limit=500,user=user)
    if rows:
        chosen=st.selectbox("Represented case",rows,format_func=lambda r:f"{r['cnr']} · {r['case_title']}")
        hearings=hearings_for_case(chosen["case_id"],user=user)
        with get_connection() as conn:
            parties=conn.execute("SELECT p.party_id,p.party_name FROM case_party cp JOIN party p USING(party_id) WHERE cp.case_id=%s ORDER BY p.party_name",(chosen["case_id"],)).fetchall()
        if hearings and parties:
            with st.form("adjournment_request"):
                hearing=st.selectbox("Hearing",hearings,format_func=lambda r:f"{r['hearing_date']} · {r['hearing_purpose']}")
                party=st.selectbox("Requesting party",parties,format_func=lambda r:r["party_name"])
                reason=st.text_area("Reason")
                new_date=st.date_input("Requested future date",value=date.today())
                asked=st.form_submit_button("Submit for judicial review",type="primary")
            if asked:
                try:
                    request_adjournment(user=user,hearing_id=hearing["hearing_id"],party_id=party["party_id"],reason=reason,revised_date=new_date)
                    st.success("Adjournment request sent for judicial review.")
                except Exception as exc:
                    show_error(exc)
        else:
            st.info("Adjournment requests require a hearing and an associated party.")
    else:
        st.info("No cases are linked to your account.")

elif page == "Agency liaison":
    st.subheader("Police and prison liaison")
    rows=get_cases(limit=500,user=user)
    if rows:
        chosen=st.selectbox("Authorized case",rows,format_func=lambda r:f"{r['cnr']} · {r['case_title']}")
        with st.form("liaison_update"):
            event=st.selectbox("Event",["SUMMONS_DISPATCHED","SERVICE_COMPLETED","BAIL_RELEASE_UPDATED","WARRANT_STATUS"])
            status=st.text_input("Current status")
            notes=st.text_area("Notes")
            submitted=st.form_submit_button("Record liaison update")
        if submitted:
            try:
                record_liaison_update(user=user,case_id=chosen["case_id"],event_type=event,status=status,notes=notes)
                st.success("Liaison update recorded in the audit trail.")
            except Exception as exc:
                show_error(exc)
        st.dataframe(pd.DataFrame(liaison_history(user=user,case_id=chosen["case_id"])),use_container_width=True,hide_index=True)
    else:
        st.info("No cases are linked to your assigned court.")

elif page == "User administration":
    st.subheader("User roles and profile links")
    options=profile_options(user=user)
    users=admin_users(user=user)
    if users:
        target=st.selectbox("Account",users,format_func=lambda r:f"{r['user_name']} · {r['role_name']} · {r['account_status']}")
        role_options=options["roles"]
        role_index=next((i for i,r in enumerate(role_options) if r["role_id"]==target["role_id"]),0)
        role_id=st.selectbox("Role",role_options,index=role_index,format_func=lambda r:r["role_name"],key=f"admin_role_{target['user_id']}")["role_id"]
        status=st.selectbox("Account status",["Active","Locked","Inactive"],index=["Active","Locked","Inactive"].index(target["account_status"]) if target["account_status"] in {"Active","Locked","Inactive"} else 0,key=f"admin_status_{target['user_id']}")
        profile_values={}
        for label,key,id_col,name_col in [("Judge","judges","judge_id","judge_name"),("Clerk","clerks","clerk_id","clerk_name"),("Lawyer","lawyers","lawyer_id","full_name"),("Court","courts","court_id","jurisdiction_area")]:
            opts=[None]+options[key]
            chosen_profile=next((i for i,r in enumerate(opts) if r is not None and r[id_col]==target[id_col]),0)
            profile_values[key]=st.selectbox(f"{label} profile",opts,index=chosen_profile,format_func=lambda r,col=name_col:"Not linked" if r is None else r[col],key=f"admin_{key}_{target['user_id']}")
        if st.button("Save role and profile links",type="primary"):
            try:
                update_user_access(user=user,target_user_id=target["user_id"],role_id=role_id,status=status,
                    judge_id=profile_values["judges"]["judge_id"] if profile_values["judges"] else None,
                    clerk_id=profile_values["clerks"]["clerk_id"] if profile_values["clerks"] else None,
                    lawyer_id=profile_values["lawyers"]["lawyer_id"] if profile_values["lawyers"] else None,
                    court_id=profile_values["courts"]["court_id"] if profile_values["courts"] else None)
                st.success("User access and associations saved.")
            except Exception as exc:
                show_error(exc)
    st.markdown("#### Create account")
    with st.form("create_user"):
        new_username=st.text_input("Username",key="new_username")
        new_password=st.text_input("Initial password (12 characters minimum)",type="password",key="new_password")
        new_email=st.text_input("Email",key="new_email")
        new_phone=st.text_input("Phone",key="new_phone")
        new_role=st.selectbox("Initial role",options["roles"],format_func=lambda r:r["role_name"],key="new_role")
        create_account=st.form_submit_button("Create account",type="primary")
    if create_account:
        try:
            new_id=create_user(user=user,username=new_username,password=new_password,role_id=new_role["role_id"],email=new_email,phone=new_phone)
            st.success(f"Account created · user ID {new_id}. Link its court or professional profile above if needed.")
        except Exception as exc:
            show_error(exc)

elif page == "Notifications":
    st.subheader("Notification queue")
    st.caption("SMTP dispatch runs only when you explicitly send queued messages and configure SMTP in `.env`.")
    notifications=queued_notifications(user=user)
    st.dataframe(pd.DataFrame(notifications),use_container_width=True,hide_index=True)
    if st.button("Send queued email notifications",type="primary"):
        try:
            sent,failed=send_queued_emails(user=user)
            st.success(f"Delivery attempts completed · sent {sent} · failed {failed}.")
        except Exception as exc:
            show_error(exc)
