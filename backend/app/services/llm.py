import json
from typing import Any

import httpx

from ..config import settings


def _rule_based_plan(mood_index: int, energy_level: int, subjects: list[str] | None) -> dict[str, Any]:
    subs = subjects or ["Mathematics", "Physics", "Literature"]
    minutes = 25 if energy_level >= 3 else 15
    blocks = []
    for i, s in enumerate(subs[:3]):
        blocks.append(
            {
                "subject": s,
                "topic": "Adaptive focus block",
                "minutes": minutes + i * 5,
                "is_current": i == 0,
            }
        )
    return {
        "mood_index": mood_index,
        "energy_level": energy_level,
        "blocks": blocks,
        "motivation": "Small steps keep momentum. You've got this.",
    }


async def generate_study_plan(
    mood_index: int,
    energy_level: int,
    subjects: list[str] | None,
) -> dict[str, Any]:
    if not settings.openai_api_key:
        return _rule_based_plan(mood_index, energy_level, subjects)

    try:
        return await _openai_plan(mood_index, energy_level, subjects)
    except Exception:
        return _rule_based_plan(mood_index, energy_level, subjects)


async def _openai_plan(
    mood_index: int,
    energy_level: int,
    subjects: list[str] | None,
) -> dict[str, Any]:
    system = (
        "You output only valid JSON with keys: blocks (array of "
        "{subject, topic, minutes, is_current}), motivation (string). "
        "Adapt length to energy 1-5 and mood 0-4."
    )
    user = json.dumps(
        {
            "mood_index": mood_index,
            "energy_level": energy_level,
            "subjects": subjects or [],
        }
    )
    async with httpx.AsyncClient(timeout=60.0) as client:
        r = await client.post(
            "https://api.openai.com/v1/chat/completions",
            headers={"Authorization": f"Bearer {settings.openai_api_key}"},
            json={
                "model": settings.openai_model,
                "response_format": {"type": "json_object"},
                "messages": [
                    {"role": "system", "content": system},
                    {"role": "user", "content": user},
                ],
            },
        )
        r.raise_for_status()
        data = r.json()
        content = data["choices"][0]["message"]["content"]
        parsed = json.loads(content)
        parsed.setdefault("mood_index", mood_index)
        parsed.setdefault("energy_level", energy_level)
        return parsed
