from datetime import date, timedelta

from psycopg import Connection


def apply_streak(conn: Connection, user_id: str, activity_day: date) -> dict:
    """Update streaks row for user after a completed session."""
    with conn.cursor() as cur:
        cur.execute(
            "select current_streak, last_activity_date, longest_streak from public.streaks where user_id = %s",
            (user_id,),
        )
        row = cur.fetchone()
        if not row:
            cur.execute(
                """
                insert into public.streaks (user_id, current_streak, last_activity_date, longest_streak)
                values (%s, 1, %s, 1)
                """,
                (user_id, activity_day),
            )
            return {"current_streak": 1, "longest_streak": 1, "last_activity_date": activity_day.isoformat()}

        current = int(row["current_streak"])
        last = row["last_activity_date"]
        longest = int(row["longest_streak"])

        if last == activity_day:
            new_current = current
        elif last is not None and last == activity_day - timedelta(days=1):
            new_current = current + 1
        else:
            new_current = 1

        new_longest = max(longest, new_current)
        cur.execute(
            """
            update public.streaks
            set current_streak = %s,
                last_activity_date = %s,
                longest_streak = %s,
                updated_at = now()
            where user_id = %s
            """,
            (new_current, activity_day, new_longest, user_id),
        )
        return {
            "current_streak": new_current,
            "longest_streak": new_longest,
            "last_activity_date": activity_day.isoformat(),
        }
