# Chapter 13: Timeline Narration

> **Positioning**: The closing chapter of Part 4, "The Time Dimension." Starting from the `timeline()` method's implementation, this chapter demonstrates how discrete temporal triples are transformed into a readable chronicle, and explores its practical value in scenarios such as new-hire onboarding.

---

## From Triples to Story

Knowledge graphs excel at answering structured queries: "What project is Kai working on now?" "Who is responsible for the auth migration?" "When did this fact expire?" But when you need to understand the complete history of an entity -- for example, when a newly joined engineer wants to quickly learn the full story behind a project -- individual triple queries fall short. What you need is not individual isolated facts but a chronologically arranged narrative.

This is the design purpose of the `timeline()` method: sorting discrete triples by time to form a readable chronicle.

---

## The Implementation of timeline()

The `timeline()` method is located at `knowledge_graph.py:274-311`. Its interface is remarkably concise:

```python
def timeline(self, entity_name: str = None):
    """Get all facts in chronological order, optionally filtered by entity."""
```

One parameter, one choice: you can view a specific entity's timeline or the entire knowledge graph's timeline.

### Entity Timeline

When `entity_name` is provided (`knowledge_graph.py:277-289`):

```python
if entity_name:
    eid = self._entity_id(entity_name)
    rows = conn.execute(
        """
        SELECT t.*, s.name as sub_name, o.name as obj_name
        FROM triples t
        JOIN entities s ON t.subject = s.id
        JOIN entities o ON t.object = o.id
        WHERE (t.subject = ? OR t.object = ?)
        ORDER BY t.valid_from ASC NULLS LAST
    """,
        (eid, eid),
    ).fetchall()
```

Three design points are worth noting.

**Bidirectional matching.** `WHERE (t.subject = ? OR t.object = ?)` -- the entity may appear on either side of a triple. When querying "Kai"'s timeline, it includes both `Kai -> works_on -> Orion` where Kai is the subject and `Priya -> manages -> Kai` where Kai is the object. This guarantees the timeline is complete -- a person's story includes not just what they did but also what happened to them.

**Chronological sorting.** `ORDER BY t.valid_from ASC` -- sorted by effective date in ascending order, placing the earliest facts first. This is the natural order of a chronicle: moving from past to present.

**NULLs sort last.** `NULLS LAST` -- facts without an explicit effective date are placed at the end of the timeline. These are "don't know when it started" facts. Placing them last rather than first is a reasonable choice: in a chronicle, events with exact dates are more referentially valuable than facts without dates and should be displayed first.

### Global Timeline

When `entity_name` is not provided (`knowledge_graph.py:291-298`):

```python
else:
    rows = conn.execute("""
        SELECT t.*, s.name as sub_name, o.name as obj_name
        FROM triples t
        JOIN entities s ON t.subject = s.id
        JOIN entities o ON t.object = o.id
        ORDER BY t.valid_from ASC NULLS LAST
        LIMIT 100
    """).fetchall()
```

The global timeline queries all triples, also sorted by time, but adds a `LIMIT 100` restriction. This is a pragmatic safety valve: if the knowledge graph contains tens of thousands of triples, returning them all at once wastes memory and overwhelms the caller. 100 records is a reasonable default -- enough to show the knowledge graph's overview without causing overload.

### Return Structure

Both queries share the same return format (`knowledge_graph.py:300-311`):

```python
return [
    {
        "subject": r[10],
        "predicate": r[2],
        "object": r[11],
        "valid_from": r[4],
        "valid_to": r[5],
        "current": r[5] is None,
    }
    for r in rows
]
```

Each record is a dictionary with six fields. `subject`, `predicate`, and `object` constitute the fact itself; `valid_from` and `valid_to` mark the time window; `current` indicates whether it is still valid.

Note that `subject` and `object` use `r[10]` and `r[11]` -- these are `sub_name` and `obj_name` from the SQL JOIN result, meaning the entity's original display name rather than the normalized ID. This is crucial for timeline narration: users should see "Kai" not "kai," "auth-migration" not an internal ID.

---

## A Complete Example

Suppose we have built the following knowledge graph for the Driftwood project:

```python
kg = KnowledgeGraph()

# Project creation
kg.add_triple("Priya", "created", "Driftwood", valid_from="2024-09-01")
kg.add_triple("Priya", "manages", "Driftwood", valid_from="2024-09-01")

# Team assembly
kg.add_triple("Kai", "joined", "Driftwood", valid_from="2024-10-01")
kg.add_triple("Soren", "joined", "Driftwood", valid_from="2024-10-15")
kg.add_triple("Maya", "joined", "Driftwood", valid_from="2024-11-01")

# Technical decisions
kg.add_triple("Driftwood", "uses", "PostgreSQL", valid_from="2024-10-10")
kg.add_triple("Kai", "recommended", "Clerk", valid_from="2026-01-01")
kg.add_triple("Driftwood", "uses", "Clerk", valid_from="2026-01-15")

# Task assignments
kg.add_triple("Maya", "assigned_to", "auth-migration", valid_from="2026-01-15")
kg.add_triple("Maya", "completed", "auth-migration", valid_from="2026-02-01")

# Personnel changes
kg.add_triple("Leo", "joined", "Driftwood", valid_from="2026-03-01")
```

Calling `kg.timeline("Driftwood")` returns:

```python
[
    {"subject": "Priya",     "predicate": "created",     "object": "Driftwood",   "valid_from": "2024-09-01", "valid_to": None,  "current": True},
    {"subject": "Priya",     "predicate": "manages",     "object": "Driftwood",   "valid_from": "2024-09-01", "valid_to": None,  "current": True},
    {"subject": "Kai",       "predicate": "joined",      "object": "Driftwood",   "valid_from": "2024-10-01", "valid_to": None,  "current": True},
    {"subject": "Driftwood", "predicate": "uses",         "object": "PostgreSQL",  "valid_from": "2024-10-10", "valid_to": None,  "current": True},
    {"subject": "Soren",     "predicate": "joined",      "object": "Driftwood",   "valid_from": "2024-10-15", "valid_to": None,  "current": True},
    {"subject": "Maya",      "predicate": "joined",      "object": "Driftwood",   "valid_from": "2024-11-01", "valid_to": None,  "current": True},
    {"subject": "Kai",       "predicate": "recommended", "object": "Clerk",       "valid_from": "2026-01-01", "valid_to": None,  "current": True},
    {"subject": "Driftwood", "predicate": "uses",         "object": "Clerk",       "valid_from": "2026-01-15", "valid_to": None,  "current": True},
    {"subject": "Maya",      "predicate": "assigned_to", "object": "auth-migration", "valid_from": "2026-01-15", "valid_to": None,  "current": True},
    {"subject": "Maya",      "predicate": "completed",   "object": "auth-migration", "valid_from": "2026-02-01", "valid_to": None,  "current": True},
    {"subject": "Leo",       "predicate": "joined",      "object": "Driftwood",   "valid_from": "2026-03-01", "valid_to": None,  "current": True},
]
```

From this result set, a human reader or an LLM can reconstruct the complete story of the Driftwood project:

> In September 2024, Priya created the Driftwood project and assumed the manager role. In October, Kai joined the team and the team chose PostgreSQL as its database. Soren joined in mid-October, followed by Maya in November.
>
> Moving into 2026, Kai recommended Clerk as the authentication solution in January, and the team formally adopted it on January 15. Maya was simultaneously assigned the auth migration task and completed it on February 1. In March, new member Leo joined the team.

This is the "from triples to story" process. The raw data is a set of discrete, structured factual records; after chronological sorting, they naturally arrange into a narrative arc, with causal relationships emerging -- Kai recommended Clerk before the team adopted Clerk; Maya was assigned the task before completing it.

---

## Sorting, Aggregation, and Formatting

The `timeline()` method itself only completes the first step: sorting. It arranges triples in ascending `valid_from` order and returns a chronologically ordered list. But between the raw list and a readable narrative, there are two additional steps typically handled by the caller.

### Aggregation

In the raw timeline, each record is an independent triple. But in a narrative, some triples should be aggregated for display. For example, both Kai and Soren joined Driftwood in October 2024; in the narrative, these can be combined as "In October, Kai and Soren joined the team in succession."

The aggregation strategy can be quite simple: group by month (or week, or day) of `valid_from`, merging similar events within the same time period. The specific grouping granularity depends on the timeline's span -- for project histories spanning several years, monthly grouping makes sense; for spans of only a few weeks, daily grouping is clearer.

### Formatting

Timeline data can be formatted into multiple forms:

**Plain text chronicle** -- like the reconstructed narrative above, suitable for directly presenting to users in conversation.

**Structured timeline** -- a bulleted list grouped by time period, suitable for quick scanning:

```
2024-09  Priya created the Driftwood project
2024-10  Kai joined | Chose PostgreSQL | Soren joined
2024-11  Maya joined
2026-01  Kai recommended Clerk | Team adopted Clerk | Maya began auth migration
2026-02  Maya completed auth migration
2026-03  Leo joined
```

**AAAK compressed format** -- using MemPalace's AAAK dialect for further compression, suitable as part of AI context:

```
TL:DRIFTWOOD|PRI.create(24-09)|KAI.join(24-10)|PG.adopt(24-10)|SOR.join(24-10)|MAY.join(24-11)|CLK.rec:KAI(26-01)|CLK.adopt(26-01)|MAY.auth-mig(26-01>26-02)|LEO.join(26-03)
```

The `timeline()` method returns structured data rather than formatted text, giving callers maximum flexibility. The MCP server can format it as a natural language reply in conversation, the CLI can format it as a terminal table output, and the AAAK compressor can convert it into an ultra-compact timeline summary.

---

## Application Scenario: New-Hire Onboarding

The most direct application of timeline narration is new-hire onboarding. When a new team member joins, they are not facing a freshly built, blank project -- they are facing a system with history, backed by countless discussions, decisions, reversals, and restarts.

Traditional onboarding relies on two information sources: documentation and oral knowledge transfer. Documentation is often outdated (last updated six months ago), and oral transfer is fragmented (depending on who you asked and what questions you posed).

Timeline narration provides a third pathway: automatically generated, chronologically arranged project history from the knowledge graph.

### An Onboarding Scenario

Leo is a new member of the Driftwood team, joining in March 2026. He knows nothing about the project. His AI assistant calls `mempalace_kg_timeline` via MCP:

```
> Tell me the history of the Driftwood project

Calling mempalace_kg_timeline("Driftwood")

Driftwood project timeline:

Sep 2024 - Priya created the project and assumed the manager role
Oct 2024 - Kai joined (backend), team chose PostgreSQL
Mid-Oct 2024 - Soren joined (frontend)
Nov 2024 - Maya joined (infrastructure)
Jan 2026 - Kai recommended Clerk over Auth0 (reasons: pricing and DX)
Jan 15, 2026 - Team adopted Clerk, Maya assigned auth migration
Feb 1, 2026 - Maya completed auth migration
Mar 2026 - You (Leo) joined the team
```

This response gives Leo a complete picture of the project in seconds. He knows who created the project, how the team was assembled, what key technical decisions were made, and why those decisions were made.

More importantly, he can continue probing for details. The timeline is an entry point, not an endpoint:

```
> Why did Kai recommend Clerk over Auth0?

Calling mempalace_search("Clerk Auth0 decision")

From conversation records in January 2026:
"Kai compared the pricing models of Clerk and Auth0 and found
Clerk to be 40% cheaper at our expected user scale. Additionally,
Clerk's SDK documentation is better and integration tests are
easier to write. The team unanimously agreed to adopt Clerk
at the January 15 meeting."
```

The timeline provides the overview, the knowledge graph's `source_closet` links can trace back to original conversation records, and the palace structure's semantic search can provide full context. The three systems work in concert, forming an information retrieval chain from "panorama" to "close-up."

### Comparison with Traditional Onboarding

| Dimension | Traditional Onboarding | Timeline Narration |
|------|-----------------|-----------|
| Information source | Documentation + oral transfer | Auto-generated from knowledge graph |
| Timeliness | Depends on manual updates | Updates in real-time with the knowledge graph |
| Completeness | Depends on the documentation maintainer's diligence | Covers all recorded facts |
| Interactivity | Static documents | Can probe for details |
| Personalization | Generic documents, no reader differentiation | Can filter by specific role or focus area |

Timeline narration cannot fully replace traditional onboarding. Some knowledge -- team culture, communication style, informal work norms -- is not well-suited for encoding as triples. But for the specific dimension of "a project's technical decision history," timeline narration provides a more reliable approach than either documentation or oral transfer.

---

## Limitations of the Timeline

The `timeline()` method is deliberately minimalist in design, and this minimalism brings some limitations.

**No causal relationships.** The timeline is merely a chronologically sorted list of facts. It cannot tell you the causal relationships between facts -- "Kai recommended Clerk" and "the team adopted Clerk" are adjacent in time, and a human reader can infer the former led to the latter, but the timeline data itself does not encode this relationship.

Causal relationships require more complex knowledge representation -- such as `caused_by` or `led_to` relationships between events. This exceeds the scope of the current temporal triple model. But from another angle, having an LLM infer causal relationships from chronologically arranged facts is precisely what LLMs excel at. The timeline provides the raw material; the LLM handles the narration.

**No importance ranking.** All facts are treated equally. "Priya created Driftwood" and "Driftwood uses PostgreSQL" occupy the same position in the timeline, but the former is clearly more important to the project narrative than the latter.

A possible improvement would be introducing importance markers (potentially leveraging the `confidence` field or adding a new `importance` field) to allow timeline filtering by importance. But this introduces the question of "who judges importance" -- which creates tension with MemPalace's core philosophy of "not letting AI decide what is important."

**The 100-record limit on global timelines.** `LIMIT 100` is a hard-coded safety valve. For small-scale knowledge graphs this is sufficient, but if the knowledge graph grows to thousands of triples, 100 records may only cover very early history. An improvement would be supporting paginated queries (providing `offset` and `limit` parameters) or supporting time range filtering (viewing only the last 6 months of the timeline).

These limitations are all deliberate design tradeoffs. MemPalace's timeline feature is positioned as "good enough" -- providing sufficient structure for an LLM to generate readable narratives, without trying to become a complete timeline analysis tool. Complex causal reasoning, importance judgment, and cross-period trend analysis are better handled at the LLM level; the timeline only needs to provide clean, chronologically sorted structured data as input.

---

## The Relationship Between Timeline and Palace Structure

Timeline narration is a microcosm of collaboration among MemPalace's three subsystems.

**The knowledge graph** provides structured facts and temporal information. The `timeline()` method obtains sorted triple lists from here.

**The palace structure** provides context and original memories. Through the `source_closet` field, each fact in the timeline can be traced back to a closet in the palace, and from the closet back to the verbatim content in a drawer.

**The AAAK dialect** provides compression capability. When timelines need to be loaded as part of AI context, AAAK can compress a complete project chronicle into very few tokens.

This collaboration is natural and seamless. The three subsystems each do their own job well -- the knowledge graph manages facts, the palace structure manages memories, AAAK manages compression -- and then cooperate through simple interfaces. No subsystem depends on another's internal implementation details.

This low-coupling, high-collaboration architectural style is one reason MemPalace can achieve rich functionality with only two external dependencies.

---

## Summary

The `timeline()` method implements the transformation from discrete triples to a chronicle in fewer than 40 lines of code (`knowledge_graph.py:274-311`). Its design follows MemPalace's consistent philosophy: simple data structures, clear query interfaces, leaving complex presentation and reasoning to the LLM.

Chronological sorting is the most basic narrative structure. The single SQL line `ORDER BY t.valid_from ASC` transforms a pile of unordered facts into a story arc. Bidirectional matching (`subject = ? OR object = ?`) ensures the story's completeness. `NULLS LAST` places facts without time information at the end, preventing them from disrupting the chronicle's main thread.

This is not a complex feature. But it does not need to be. It only needs to provide good enough raw material, letting the LLM complete the final mile of "storytelling." This division of labor -- "infrastructure does simple things, the intelligence layer does complex things" -- is a pattern that recurs throughout MemPalace's architecture.

With this, Part 4, "The Time Dimension," concludes. We have seen how the temporal knowledge graph gives facts lifecycles (Chapter 11), how it leverages temporal information to detect contradictions (Chapter 12), and how it weaves discrete temporal facts into a readable narrative (Chapter 13). Together, these three chapters demonstrate a core insight: in AI memory systems, **time is not metadata -- time is the data itself**.
