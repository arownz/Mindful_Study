from datetime import date, datetime, timezone

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field

from ..deps.auth import get_current_user_id
from ..db import get_conn
from ..services.streaks import apply_streak

router = APIRouter(prefix="/sessions", tags=["sessions"])


class CompleteSessionBody(BaseModel):
    subject: str | None = None
    duration_seconds: int = Field(ge=0)
    mood_before: int | None = Field(default=None, ge=0, le=4)
    mood_after: int | None = Field(default=None, ge=0, le=4)
    completed_at: datetime | None = None


@router.post("/complete")
def complete_session(
    body: CompleteSessionBody,
    user_id: str = Depends(get_current_user_id),
):
    completed = body.completed_at or datetime.now(timezone.utc)
    activity_day = completed.date()

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into public.study_sessions
                  (user_id, subject, duration_seconds, completed_at, mood_before, mood_after)
                values (%s, %s, %s, %s, %s, %s)
                returning id
                """,
                (
                    user_id,
                    body.subject,
                    body.duration_seconds,
                    completed,
                    body.mood_before,
                    body.mood_after,
                ),
            )
            row = cur.fetchone()
            session_id = str(row["id"]) if row else None
        streak = apply_streak(conn, user_id, activity_day)

    return {"session_id": session_id, "streak": streak}
