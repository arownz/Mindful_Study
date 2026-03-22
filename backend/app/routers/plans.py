from typing import Any

from fastapi import APIRouter, Depends
from pydantic import BaseModel, Field
from psycopg.types.json import Json

from ..config import settings
from ..deps.auth import get_current_user_id
from ..db import get_conn
from ..services.llm import generate_study_plan

router = APIRouter(prefix="/plans", tags=["plans"])


class GeneratePlanBody(BaseModel):
    mood_index: int = Field(ge=0, le=4)
    energy_level: int = Field(ge=1, le=5)
    subjects: list[str] | None = None


@router.post("/generate")
async def generate_plan(
    body: GeneratePlanBody,
    user_id: str = Depends(get_current_user_id),
) -> dict[str, Any]:
    plan = await generate_study_plan(body.mood_index, body.energy_level, body.subjects)
    source = "ai" if settings.openai_api_key else "rule_based"
    with get_conn() as conn:
        with conn.cursor() as cur:
            cur.execute(
                """
                insert into public.study_plans (user_id, plan_json, source)
                values (%s, %s, %s)
                returning id
                """,
                (user_id, Json(plan), source),
            )
            row = cur.fetchone()
    plan["plan_id"] = str(row["id"]) if row else None
    return plan
