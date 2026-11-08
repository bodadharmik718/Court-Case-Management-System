"""Queue and explicitly dispatch email notifications when SMTP is configured."""
from email.message import EmailMessage
import smtplib
import ssl

from auth.permissions import require_permission
from config.settings import settings
from database.connection import get_connection


def send_queued_emails(*, user: dict, limit: int = 25) -> tuple[int,int]:
    require_permission(user,"NOTIFICATION_MANAGE")
    if not settings.smtp_host or not settings.smtp_from:
        raise RuntimeError("SMTP_HOST and SMTP_FROM must be configured before sending queued email.")
    with get_connection() as conn:
        queued = conn.execute("""SELECT notification_id,message,recipient FROM notification
            WHERE channel='EMAIL' AND status IN ('QUEUED','FAILED') AND attempt_count<3
            ORDER BY notification_date LIMIT %s FOR UPDATE SKIP LOCKED""",(limit,)).fetchall()
        sent=failed=0
        for item in queued:
            outcome="FAILED"
            error=None
            try:
                message=EmailMessage()
                message["Subject"]="Court case system notification"
                message["From"]=settings.smtp_from
                message["To"]=item["recipient"]
                message.set_content(item["message"])
                with smtplib.SMTP(settings.smtp_host,settings.smtp_port,timeout=15) as server:
                    if settings.smtp_starttls:
                        server.starttls(context=ssl.create_default_context())
                    if settings.smtp_user:
                        server.login(settings.smtp_user,settings.smtp_password)
                    server.send_message(message)
                outcome="SENT"
                sent+=1
            except Exception as exc:
                error=type(exc).__name__
                failed+=1
            conn.execute("INSERT INTO notification_delivery_attempt(notification_id,outcome,error_detail) VALUES (%s,%s,%s)",(item["notification_id"],outcome,error))
            conn.execute("UPDATE notification SET status=%s,attempt_count=attempt_count+1,last_error=%s,sent_at=CASE WHEN %s='SENT' THEN CURRENT_TIMESTAMP ELSE sent_at END WHERE notification_id=%s",
                ("SENT" if outcome=="SENT" else "FAILED",error,outcome,item["notification_id"]))
            conn.execute("""INSERT INTO audit_log(action_performed,user_id,case_id,event_type,entity_name,entity_id,post_modification_state)
                SELECT 'NOTIFICATION_DELIVERY_ATTEMPT',%s,case_id,'NOTIFY','notification',%s,%s FROM notification WHERE notification_id=%s""",
                (user["user_id"],item["notification_id"],outcome,item["notification_id"]))
        return sent,failed


def queued_notifications(*, user: dict) -> list[dict]:
    require_permission(user,"NOTIFICATION_MANAGE")
    with get_connection() as conn:
        return conn.execute("SELECT notification_id,recipient,status,attempt_count,last_error,notification_date FROM notification ORDER BY notification_date DESC LIMIT 200").fetchall()
