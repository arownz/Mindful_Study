from app.services.llm import _rule_based_plan


def test_rule_based_has_blocks():
    p = _rule_based_plan(2, 4, ["Math"])
    assert "blocks" in p
    assert len(p["blocks"]) >= 1
    assert p["blocks"][0]["subject"] == "Math"
