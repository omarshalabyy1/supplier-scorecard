"""Write each department's weekly summary with a local LLM, and check it before saving.

Run: python summarize.py   (Ollama must be running; the week and the model are in config/client.yaml, summary.*)

The numbers come from the warehouse; the model only puts them into words. Three checks guard every
summary: each number in it must be one of the facts, each supplier it names must be the one in the
facts, and it must say the late rate went the way it really went. A summary that fails is written
again; after three tries the run stops and saves nothing.
"""
import json
import re
from datetime import date

import psycopg
import requests
from pydantic import BaseModel, Field, ValidationError

from config import load_config

OLLAMA = "http://localhost:11434/api/chat"

# The scorecard rules, the same as the DAX measures (grace days from star.client_setting),
# for one week and the week before it.
FACTS_SQL = """
WITH line AS (
    SELECT DATE_TRUNC('week', f.due_date)::date = %(week)s                                       AS this_week,
           f.delivered_date IS NOT NULL                                                          AS delivered,
           f.delivered_date IS NOT NULL AND f.delivered_date <= f.due_date + c.on_time_grace_days AS on_time,
           f.delivered_date > f.due_date + c.on_time_grace_days                                  AS late
    FROM star.fact_order_line f
    JOIN star.dim_product p USING (product_key)
    CROSS JOIN star.client_setting c
    WHERE DATE_TRUNC('week', f.due_date)::date IN (%(week)s, %(week)s - 7)
      AND (%(department)s::text IS NULL OR p.department = %(department)s)
)
SELECT COUNT(*) FILTER (WHERE this_week)                                                   AS lines,
       ROUND(100.0 * COUNT(*) FILTER (WHERE this_week AND late)
                   / NULLIF(COUNT(*) FILTER (WHERE this_week AND delivered), 0), 1)        AS late_rate,
       ROUND(100.0 * COUNT(*) FILTER (WHERE NOT this_week AND late)
                   / NULLIF(COUNT(*) FILTER (WHERE NOT this_week AND delivered), 0), 1)    AS late_rate_last_week,
       ROUND(100.0 * COUNT(*) FILTER (WHERE this_week AND on_time)
                   / NULLIF(COUNT(*) FILTER (WHERE this_week), 0), 1)                      AS otif
FROM line
"""

WORST_SUPPLIER_SQL = """
SELECT s.supplier, COUNT(*) AS late_lines
FROM star.fact_order_line f
JOIN star.dim_product p  USING (product_key)
JOIN star.dim_supplier s USING (supplier_key)
CROSS JOIN star.client_setting c
WHERE DATE_TRUNC('week', f.due_date)::date = %(week)s
  AND f.delivered_date > f.due_date + c.on_time_grace_days
  AND (%(department)s::text IS NULL OR p.department = %(department)s)
GROUP BY s.supplier
ORDER BY late_lines DESC, s.supplier
LIMIT 1
"""

PROMPT = """You write the weekly delivery summary for a retail buyer, in two or three short, plain sentences.
Say how many order lines were due, the late rate exactly as written in "late rate", the share on time
and in full, and the supplier to follow up with (or that none is needed).
Use only the facts you are given and copy every number exactly; never calculate a new number.

Example, for other facts:
Garden: 120 order lines were due this week. The late rate was 4.2%, down from 5.0% last week, and 94.1%
arrived on time and in full. Follow up with S0123, which had 3 late lines."""

# What the summary must say, and must not say, for each way the late rate can move.
RIGHT_WAY = {"down": "down from", "up": "up from", "unchanged": "the same as"}
WRONG_WAY = {"down": ["up from", "increase", "rose"], "up": ["down from", "decrease", "fell"],
             "unchanged": ["up from", "down from"]}


class Summary(BaseModel):
    summary: str = Field(min_length=80)


def numbers(text):
    """Every number written in a text, ignoring codes like S0082."""
    return {float(n.replace(",", "")) for n in re.findall(r"(?<![\w.])\d[\d,]*(?:\.\d+)?", text)}


def suppliers(text):
    return set(re.findall(r"\bS\d{4}\b", text))


def problems(text, facts, trend):
    found = [f"number {n:g} is not in the facts" for n in sorted(numbers(text) - numbers(json.dumps(facts)))]
    found += [f"supplier {s} is not in the facts" for s in sorted(suppliers(text) - suppliers(json.dumps(facts)))]
    lower = text.lower()
    if RIGHT_WAY[trend] not in lower or any(w in lower for w in WRONG_WAY[trend]):
        found.append(f"does not say the late rate went {trend}")
    return found


def write_summary(facts, trend, model):
    for _ in range(3):
        reply = requests.post(OLLAMA, timeout=300, json={
            "model": model,
            "stream": False,
            "format": Summary.model_json_schema(),
            "options": {"temperature": 0.3},
            "messages": [{"role": "system", "content": PROMPT},
                         {"role": "user", "content": json.dumps(facts)}],
        }).json()
        if "error" in reply:
            raise SystemExit(f"Ollama: {reply['error']}")
        try:
            text = Summary.model_validate_json(reply["message"]["content"]).summary.strip()
        except ValidationError:
            print("  retry: too short")
            continue
        found = problems(text, facts, trend)
        if not found:
            return text
        print(f"  retry: {'; '.join(found)}")
    raise SystemExit(f"No checked summary for {facts['department']} after three tries; nothing saved.")


cfg = load_config()
week = date.fromisoformat(cfg["summary"]["week"])
if week.weekday() != 0:
    raise SystemExit("summary.week in config/client.yaml must be a Monday (the start of the week).")

with psycopg.connect(cfg["db_url"]) as conn:
    departments = [None] + [d for (d,) in conn.execute("SELECT department FROM star.buyer ORDER BY department")]
    for department in departments:
        params = {"week": week, "department": department}
        lines, late_rate, last_week, otif = conn.execute(FACTS_SQL, params).fetchone()
        if not lines or late_rate is None or last_week is None:
            print(f"{department or 'All departments'}: not enough deliveries in one of the two weeks, skipped")
            continue
        trend = "down" if late_rate < last_week else "up" if late_rate > last_week else "unchanged"
        facts = {
            "department": department or "All departments",
            "week": week.strftime("%d %b %Y"),
            "order lines due": lines,
            "late rate": f"{late_rate}%, {RIGHT_WAY[trend]} {last_week}% last week",
            "on time and in full": f"{otif}%",
        }
        worst = conn.execute(WORST_SUPPLIER_SQL, params).fetchone()
        facts["supplier to follow up"] = f"{worst[0]} ({worst[1]} late lines)" if worst else "none, no late lines"

        text = write_summary(facts, trend, cfg["summary"]["model"])
        conn.execute("""INSERT INTO star.weekly_summary (week_start, department, summary) VALUES (%s, %s, %s)
                        ON CONFLICT (week_start, department) DO UPDATE SET summary = EXCLUDED.summary, created_at = now()""",
                     (week, facts["department"], text))
        print(f"{facts['department']}: {text}")
