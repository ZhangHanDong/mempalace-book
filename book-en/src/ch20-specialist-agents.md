# Chapter 20: Specialist Agent System

> **Positioning**: This chapter analyzes how MemPalace uses the palace's spatial structure -- rather than configuration-file bloat -- to host an unlimited number of specialist agents, and why it models each agent's memory as `wing + diary`. AAAK diary format is encouraged in the README and tool descriptions; the part the current MCP runtime actually implements is the storage structure of one wing and one diary room per agent.

---

## The Configuration Dilemma of Specialist Agents

Suppose you have 50 AI agents, each responsible for a specialized domain. One reviews code quality, one tracks architectural decisions, one monitors operational incidents, one records product requirements, one watches for security vulnerabilities. In traditional agent frameworks, each agent needs independent configuration -- system prompts, memory storage, state management, permission scopes. 50 agents means 50 configuration files, or an ever-growing central configuration.

Letta (formerly MemGPT) chose the centralized path: each agent has independent memory blocks, independent system prompts, independent core memory and archival memory. All of these are stored in the cloud and managed via API. This is clean, but costs scale linearly -- the free tier gets 1 agent, the developer tier is $20/month for 10 agents, the business tier is $200/month for 100 agents. Agent count is directly tied to wallet depth.

MemPalace chose an entirely different path: agents don't live in configuration files -- agents live in the palace.

---

## One Agent = One Wing + One Diary

Return to the diary tools in `mcp_server.py`. The first three lines of `tool_diary_write` (lines 349-392) reveal the entire architecture:

```python
def tool_diary_write(agent_name, entry, topic="general"):
    wing = f"wing_{agent_name.lower().replace(' ', '_')}"
    room = "diary"
    col = _get_collection(create=True)
```

When an agent named "reviewer" writes a diary entry, its entry is stored in `wing_reviewer/diary`. When "architect" writes a diary entry, it goes into `wing_architect/diary`. An agent's identity is determined by its wing name, and an agent's memory is carried by its diary room. No additional configuration file is needed to "register" an agent -- the wing is automatically created on the first call to `diary_write`.

The metadata structure (`mcp_server.py:368-380`) further reinforces this naturalness:

```python
col.add(
    ids=[entry_id],
    documents=[entry],
    metadatas=[{
        "wing": wing,
        "room": room,
        "hall": "hall_diary",
        "topic": topic,
        "type": "diary_entry",
        "agent": agent_name,
        "filed_at": now.isoformat(),
        "date": now.strftime("%Y-%m-%d"),
    }],
)
```

Each diary entry carries complete spatial coordinates -- wing (which agent), room (diary), hall (hall_diary), topic (topic tag) -- plus temporal coordinates (`filed_at`, `date`) and identity markers (`agent`). That is enough to let diary entries flow into the palace's existing infrastructure: `search` can find them, `list_rooms` can count them, and graph-building logic will still see `diary` as an ordinary room. More cautiously stated, the current code does not provide a diary-specific topic filter or a higher-level agent-orchestration layer; at runtime these are still ordinary drawers with agent-flavored metadata.

Agents aren't add-ons external to the palace. Agents are residents of the palace.

---

## AAAK Diary: Compressed Self-Awareness

When agents write diary entries, the **interface contract** encourages AAAK. Look at the `diary_write` tool's description (`mcp_server.py:649`):

```
Write to your personal agent diary in AAAK format. Your observations,
thoughts, what you worked on, what matters. Write in AAAK for
compression — e.g. 'SESSION:2026-04-04|built.palace.graph+diary.tools
|ALC.req:agent.diaries.in.aaak|★★★★'
```

The tool description directly demonstrates the AAAK diary format. A typical agent diary entry looks like this:

```
PR#42|auth.bypass.found|missing.middleware.check|pattern:3rd.time.this.quarter|★★★★
```

This single line compresses the following information: during PR #42 review, an authentication bypass vulnerability was found, caused by a missing middleware check, this is the third occurrence of the same pattern this quarter, importance four stars. In natural language, this would take at least three lines. In AAAK, one line does the job.

The tool description directly demonstrates the AAAK diary format. But this is exactly where "interface contract" and "runtime enforcement" must be separated. `tool_diary_write` does not validate that the input is AAAK, nor does it automatically compress natural language into AAAK; it simply stores whatever string the caller passes in. So the token-efficiency benefit is real, but only if the caller chooses to follow the AAAK convention.

That means the more accurate claim is: if a code review agent consistently writes its observations in AAAK, then reading the latest 10 diary entries can indeed restore recent work patterns with a very small token budget. If it writes plain English, `diary_read` still works -- it just costs more context.

AAAK diary's pipe-delimited syntax is still especially useful here. `pattern:3rd.time.this.quarter` records not just a fact but a trend. When the agent later reviews another authentication-related PR, reading these diary entries can bring that pattern back into the current session. A diary is not a log; it is a compressed encoding of a learning curve. In the current implementation, though, that compression happens because the caller voluntarily writes AAAK, not because the MCP server enforces or performs it.

---

## 50 Agents, One Line of Configuration

The most counterintuitive feature of MemPalace's agent system is: no matter how many agents you have, your CLAUDE.md (or any system configuration file) doesn't need to change. The configuration shown in the README is:

```
You have MemPalace agents. Run mempalace_list_agents to see them.
```

One line. Not "you have an agent called reviewer, it focuses on code quality, its system prompt is..." Instead, it tells the AI: you have agents, go look in the palace to see which ones.

The README then sketches a fuller runtime-discovery mechanism, with agent definition files stored in the `~/.mempalace/agents/` directory:

```
~/.mempalace/agents/
  ├── reviewer.json       # code quality, pattern recognition, bug tracking
  ├── architect.json      # design decisions, trade-off analysis, architecture evolution
  └── ops.json            # deployment, incident response, infrastructure
```

That tells a clear product-direction story: agent descriptors live in a local directory, top-level configuration stays one line long, and runtime discovery fills in the rest. **But if you compare this strictly against the current `mcp_server.py`, one important truth has to be added: the repository does not implement `mempalace_list_agents`, nor does it load `~/.mempalace/agents/*.json`.** What is really shipped today is the minimum storage structure provided by `diary_write` / `diary_read`; the README's agent directory and discovery flow are better read as a proposed higher-level workflow.

So "adding the 51st agent" needs to be split into two layers. At the current MCP layer, it simply means calling `diary_write` with a new `agent_name`; the system will naturally start writing into `wing_<agent>/diary` with no schema migration, no extra instance, and no central registry. In the fuller README experience, it would additionally involve an agent JSON file and a runtime discovery step.

Compare this to Letta's model: each agent has independent core memory (always-loaded key facts), recall memory (searchable history), and archival memory (long-term storage). All of these are managed via REST API and stored in the cloud. Adding an agent means creating an agent instance, configuring its memory blocks, setting up its system prompt, and managing its API keys. 50 agents means doing this 50 times, plus ongoing monthly fees.

MemPalace compresses all of this into one wing and one diary. Core memory is the most recent N diary entries. Recall memory is semantic search over the diary room. Archival memory is the other rooms in the wing. A three-layer memory architecture is implicit in the palace's spatial structure, requiring no explicit management.

---

## Tunnels Between Agents: Natural Emergence of Shared Memory

An unexpected advantage of the palace architecture is knowledge connections between agents.

When the reviewer agent records `auth.bypass.found|missing.middleware.check` in `wing_reviewer/diary`, and the architect agent records `auth.migration.decision|clerk>auth0|middleware.layer.critical` in `wing_architect/diary` -- each writes in its own wing, without interference. But `mempalace_search("middleware")` returns both records. `mempalace_find_tunnels("wing_reviewer", "wing_architect")` discovers they share a "diary" room (albeit with different content).

The current implementation boundary matters here too. `searcher.py` supports only `wing` and `room` filters; it does not support diary-specific filtering like `topic=auth`, and `traverse` aggregates by room name rather than topic. So MemPalace already provides "multiple agents can keep memory inside the same palace and be searched together" at one level, but it does not yet provide a finer-grained agent-topic orchestration layer.

---

## Diary Reading: Recent Self-Review

The implementation of `tool_diary_read` (`mcp_server.py:395-436`) reveals the diary system's final design detail:

```python
def tool_diary_read(agent_name, last_n=10):
    wing = f"wing_{agent_name.lower().replace(' ', '_')}"
    col = _get_collection()
    results = col.get(
        where={"$and": [{"wing": wing}, {"room": "diary"}]},
        include=["documents", "metadatas"],
    )
    # ... sort by timestamp, return latest N
```

It uses `$and` conditions to precisely locate the agent's diary -- wing matches the agent name, room is fixed as "diary." Then it sorts by timestamp in descending order and returns the most recent N entries.

The default value `last_n=10` is a considered choice. Too few (say 3), and the agent loses trend awareness -- it can't see "this problem keeps recurring." Too many (say 50), and a recent self-review starts to consume unnecessary context budget. There is no need to pretend the code contains an exact token manager here; what the source really does is simpler: return the latest N entries and let the caller decide how to consume them.

The `total` field in the return structure tells the agent how long its complete diary is:

```python
return {
    "agent": agent_name,
    "entries": entries,
    "total": len(results["ids"]),
    "showing": len(entries),
}
```

An agent with 200 historical diary entries but showing only 10 knows it has rich history but currently sees only the most recent slice. If it needs earlier memories, it can do semantic search within its own wing via `mempalace_search`. The diary is a fast lane for recent review; search is the backup path for deep recall.

---

## Three Layers Deep: The Meaning Stack of Agent Architecture

Stacking up the three layers of what an agent means:

**First layer: storage.** An agent is a wing. A wing is a metadata tag in ChromaDB, not a separate database. Adding an agent means adding a tag value -- the system's complexity doesn't increase. This is linear scaling from 0 to N agents -- but the cost function's slope is zero (not counting storage itself).

**Second layer: cognition.** If the caller follows the tool description and writes diary entries in AAAK, then the diary records not just facts but patterns (`pattern:3rd.time`), importance assessments (star ratings), and emotion markers (`*fierce*`, `*raw*`). When an agent reads those entries in a new session, it is not merely recalling what happened -- it is rebuilding its understanding of the domain. A reviewer agent that has reviewed 200 PRs, after reading 10 recent compressed diary entries, has sharper code quality perception than a fresh AI with no history.

**Third layer: ecosystem.** Multiple agents accumulate domain expertise in the same palace, and their memories are connected through the palace's search and navigation infrastructure. Bug patterns found by the reviewer may relate to the architect's design decisions; incidents recorded by ops may corroborate the reviewer's code quality concerns. These connections don't need to be manually established -- they emerge naturally through shared semantic space and namespace.

These three layers together answer a bigger question: where should AI agent memory live?

In CLAUDE.md? That's configuration bloat -- every additional agent means another section in the configuration file. In separate databases? That's infrastructure bloat -- every additional agent means another storage instance to manage. In cloud services? That's cost bloat -- every additional agent means another line item on the monthly bill.

In one wing of the palace? That's a tag. The palace already has search, navigation, knowledge graph, and compression. The agent is simply a new consumer of these existing capabilities. It doesn't add infrastructure, doesn't add configuration, doesn't add monthly fees. It only adds memory -- and memory is the very reason the palace exists.

---

## Version Evolution: v3.0.0 → v3.3.0

In v3.0.0 this chapter described "the design path for an agent system" — `diary_write` / `diary_read` existed, but specialist agents as runtime roles weren't yet implemented. v3.3.0 adds three modules that directly fill in this space, but along a slightly different trajectory from what the chapter anticipated.

### fact_checker.py — the first "local specialist agent"

v3.3.0 adds `mempalace/fact_checker.py` (335 lines). It is not the "agent that accumulates experience in a wing" the chapter envisioned — instead it is a **stateless, purely-offline validator**: given a text, it checks against `entity_registry.json` and the KG SQLite for three issue classes (`similar_name` near-duplicate names, `relationship_mismatch` role conflicts, `stale_fact` expired facts), and returns an `issues` list. Note that it is **not wired into any ingest path** — not as a pre-hook in `miner.py`, not as an automatic check in `mcp_server.py`'s write paths. Today it can only be invoked manually via CLI (`python -m mempalace.fact_checker "..."`) or by direct import (`from mempalace.fact_checker import check_text`).

It is thus another shape of "specialist": expertise embedded in code and data rather than accumulated in a diary — but the current shape is "an optional tool," not "a pipeline component." To become an actual "pre-ingest quality gate," it would need to be explicitly wired into an ingest path. v3.3.0 hasn't taken that step.

This is **complementary, not replacement**, to the chapter's second meaning-stack layer (accumulate cognitive patterns in AAAK diary). fact_checker gives you a manually-invokable fact-consistency checkpoint; diary handles post-ingest experience sedimentation. Strung together in the future they would form a complete agent pipeline — today they are still independent.

### closet_llm.py — the optional LLM specialist

v3.3.0 adds `mempalace/closet_llm.py` (351 lines, PR `#793`). It allows calling an external LLM at the closet layer to regenerate compressed summaries — with a critical constraint: "bring-your-own endpoint, no mandatory API key."

This is a stress test of the chapter's "local-first, no compromise" ethos: the first time LLMs enter the pipeline, while insisting **no API key is mandatory**. The default path remains 100% local (keywords, BM25, embeddings); LLMs are only invoked when the user explicitly configures an endpoint — including self-hosted local inference servers (ollama, llama.cpp, vLLM).

This "optional external capability + local default" design had no precedent in v3.0.0. The chapter's "agent architecture" extends from "a wing is enough" to "a wing + an optional external brain" — but the default form is unchanged.

### diary_ingest.py — day-aggregated diary ingest

v3.3.0 adds `mempalace/diary_ingest.py` (209 lines). Its actual shape differs slightly from what the chapter anticipated — **the room is hardcoded to `"daily"`** (`diary_ingest.py:141,171`); the date is not in the room name but in the drawer's metadata `date` field and in the drawer_id hash. That is, the v3.3.0 diary structure is: inside a single `(wing, room="daily")` room, each day precipitates one date-tagged drawer — not one room per day.

The MCP `diary_write` tool (`mcp_server.py:902-903`) uses a different code path: the wing is `f"wing_{agent_name.lower().replace(' ', '_')}"` and the room is hardcoded to `"diary"` — i.e., each agent gets its own `diary` room. This is not the same room name as `diary_ingest.py`'s `"daily"`; the two paths have not been unified. The chapter's closing "reviewer agent reading 10 recent compressed diaries" maps in v3.3.0 to "sort by `filed_at` inside `(wing_reviewer, diary)` and take the most recent few," not "take drawers from the most recent few day-rooms."

### Impact on the chapter's core argument

Unchanged:
- agent = wing (one metadata tag)
- Cost-function slope is zero (new agents don't add infrastructure)
- Three-layer meaning stack (storage / cognitive / ecosystem) holds

Revised:
- v3.0.0: "agents only accumulate via `diary_write`." v3.3.0: two more optional paths — `fact_checker`'s offline fact-consistency check (still a manually-invokable tool, not an automatic pipeline) and `closet_llm`'s optional LLM brain.
- "No API key" — still true in v3.3.0; `closet_llm` simply lets you **choose** to plug in an LLM endpoint whose contents you control.
