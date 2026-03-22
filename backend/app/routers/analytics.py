from datetime import date, timedelta

from fastapi import APIRouter, Depends

from ..deps.auth import get_current_user_id
from ..db import get_conn

router = APIRouter(prefix="/analytics", tags=["analytics"])


@router.get("/summary")
def analytics_summary(user_id: str = Depends(get_current_user_id)):
    today = date.today()
    week_start = today - timedelta(days=6)

    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                select coalesce(sum(duration_seconds), 0) as total_seconds,
                       count(*)::int as session_count
                from public.study_sessions
                where user_id = %s
                  and completed_at::date between %s and %s
                """,
                (user_id, week_start, today),
            )
            wk = cur.fetchone()

            cur.execute(
                """
                select coalesce(sum(duration_seconds), 0) as total_seconds,
                       count(*)::int as session_count
                from public.study_sessions
                where user_id = %s
                  and date_trunc('month', completed_at::date) = date_trunc('month', %s::date)
                """,
                (user_id, today),
            )
            mo = cur.fetchone()

            cur.execute(
                """
                select current_streak, longest_streak, last_activity_date
                from public.streaks
                where user_id = %s
                """,
                (user_id,),
            )
            st = cur.fetchone()

            cur.execute(
                """
                select round(avg(mood_index)::numeric, 2) as avg_mood
                from public.mood_logs
                where user_id = %s
                  and created_at::date between %s and %s
                """,
                (user_id, week_start, today),
            )
            mood = cur.fetchone()

    total_week_seconds = int(wk["total_seconds"] or 0) if wk else 0
    total_month_seconds = int(mo["total_seconds"] or 0) if mo else 0

    return {
        "week": {
            "total_minutes": total_week_seconds // 60,
            "session_count": wk["session_count"] if wk else 0,
            "avg_mood": float(mood["avg_mood"]) if mood and mood["avg_mood"] is not None else None,
        },
        "month": {
            "total_minutes": total_month_seconds // 60,
            "session_count": mo["session_count"] if mo else 0,
        },
        "streak": {
            "current": int(st["current_streak"]) if st else 0,
            "longest": int(st["longest_streak"]) if st else 0,
            "last_activity": st["last_activity_date"].isoformat() if st and st["last_activity_date"] else None,
        },
    }
