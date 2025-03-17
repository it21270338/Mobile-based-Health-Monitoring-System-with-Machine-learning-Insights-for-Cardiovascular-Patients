# notification_service/email.py
import smtplib
from email.message import EmailMessage

SMTP_HOST = "smtp.gmail.com"
SMTP_PORT = 587
SMTP_USERNAME = "shehan.krishan.dev@gmail.com"
SMTP_PASSWORD = "obek qfqv wual htjo"

async def send_email(to_email: str, subject: str, content: str):
    msg = EmailMessage()
    msg["From"] = SMTP_USERNAME
    msg["To"] = to_email
    msg["Subject"] = subject
    msg.set_content(content)

    try:
        with smtplib.SMTP(SMTP_HOST, SMTP_PORT) as s:
            s.starttls()
            s.login(SMTP_USERNAME, SMTP_PASSWORD)
            s.send_message(msg)
        return True
    except Exception as e:
        print(f"Failed to send email: {str(e)}")
        return False
