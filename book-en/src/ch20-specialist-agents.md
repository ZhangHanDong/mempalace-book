# Chapter 20: Specialist Agent System

> **Positioning**: This chapter analyzes how MemPalace uses the palace's spatial structure -- rather than configuration file bloat -- to host an unlimited number of specialist agents, and why each agent's memory is an AAAK diary rather than a separate database.

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

Each diary entry carries complete spatial coordinates -- wing (which agent), room (diary), hall (hall_diary), topic (topic tag) -- plus temporal coordinates (`filed_at`, `date`) and identity markers (`agent`). This metadata enables diary entries to be processed by all of the palace's existing infrastructure: `search` can search them, `traverse` can follow tunnels from one agent's diary to another agent's related memories, `list_rooms` can display each agent's diary size.

Agents aren't add-ons external to the palace. Agents are residents of the palace.

---

## AAAK Diary: Compressed Self-Awareness

The format agents use to write diary entries is AAAK -- this isn't an accidental default but a core system design choice. Look at the `diary_write` tool's description (`mcp_server.py:649`):

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

The value of compression is realized in `diary_read`. When an agent reads its own history in a new session (`mcp_server.py:395-436`), it loads the most recent 10 diary entries. If each entry is three lines of natural language, 10 entries would be 30 lines, roughly 300-400 tokens. If each entry is one line of AAAK, 10 entries are 10 lines, roughly 50-80 tokens.

For a code review agent, 50 tokens is enough to load complete summaries of its last 10 reviews -- what issues were found, in which PRs, how many occurrences, how important. 300 tokens could accomplish the same thing, but at the cost of occupying context window space. In a workflow that already needs to load code diffs, test outputs, and team standards, a 250-token difference means being able to review one or two more files.

AAAK diary's pipe-delimited syntax shows particular advantage here. `pattern:3rd.time.this.quarter` records not just a fact but a trend. When the agent next reviews an authentication-related PR, it reads its diary, sees this pattern marker, and knows to pay special attention to middleware checks -- because history tells it this is a recurring problem. A diary isn't a log; a diary is a compressed encoding of a learning curve.

---

## 50 Agents, One Line of Configuration

The most counterintuitive feature of MemPalace's agent system is: no matter how many agents you have, your CLAUDE.md (or any system configuration file) doesn't need to change. The configuration shown in the README is:

```
You have MemPalace agents. Run mempalace_list_agents to see them.
```

One line. Not "you have an agent called reviewer, it focuses on code quality, its system prompt is..." Instead, it tells the AI: you have agents, go look in the palace to see which ones.

The underlying mechanism of this design is runtime discovery. Agent definition files are stored in the `~/.mempalace/agents/` directory:

```
~/.mempalace/agents/
  ├── reviewer.json       # code quality, pattern recognition, bug tracking
  ├── architect.json      # design decisions, trade-off analysis, architecture evolution
  └── ops.json            # deployment, incident response, infrastructure
```

Each JSON file defines the agent's focus areas and behavioral patterns. But the key point is: these files don't need to be referenced in any central configuration. The AI discovers them at runtime through the palace's wing list -- `list_wings` returns all wings, and those named with `wing_` plus the agent name are the agent wings. Diary content is loaded via `diary_read`.

Adding the 51st agent means: create a JSON file, then let the agent start writing diary entries. No global configuration needs to be modified, no services need to be restarted, no prompt templates need to be updated. The palace's space is infinite -- adding one more wing has the same impact on the system as adding one more room: zero configuration bloat.

Compare this to Letta's model: each agent has independent core memory (always-loaded key facts), recall memory (searchable history), and archival memory (long-term storage). All of these are managed via REST API and stored in the cloud. Adding an agent means creating an agent instance, configuring its memory blocks, setting up its system prompt, and managing its API keys. 50 agents means doing this 50 times, plus ongoing monthly fees.

MemPalace compresses all of this into one wing and one diary. Core memory is the most recent N diary entries. Recall memory is semantic search over the diary room. Archival memory is the other rooms in the wing. A three-layer memory architecture is implicit in the palace's spatial structure, requiring no explicit management.

---

## Tunnels Between Agents: Natural Emergence of Shared Memory

An unexpected advantage of the palace architecture is knowledge connections between agents.

When the reviewer agent records `auth.bypass.found|missing.middleware.check` in `wing_reviewer/diary`, and the architect agent records `auth.migration.decision|clerk>auth0|middleware.layer.critical` in `wing_architect/diary` -- each writes in its own wing, without interference. But `mempalace_search("middleware")` returns both records. `mempalace_find_tunnels("wing_reviewer", "wing_architect")` discovers they share a "diary" room (albeit with different content).

An even more interesting case is when agents use the same topic tags. If the reviewer's diary topic is "auth" and the architect's diary topic is also "auth," then a filtered search on `hall_diary` with `topic=auth` hits both agents' memories. Two independent experts' independent observations on the same topic are automatically linked by the palace's structure.

This linkage requires no inter-agent communication protocol. No message queues, no shared memory, no publish-subscribe. Agents each write their own diaries, and the palace's search and navigation infrastructure automatically connects related memories. This is emergent collaboration -- not designed, but naturally growing from the spatial structure.

---

## Diary Reading: Chronological Self-Review

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

The default value `last_n=10` is a considered choice. Too few (say 3), and the agent loses trend awareness -- it can't see "this problem keeps recurring." Too many (say 50), and the diary's token overhead exceeds its value -- 50 AAAK diary entries are roughly 400 tokens, already approaching the L1 layer's budget. 10 strikes a balance between trend recognition and token economy.

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

**Second layer: cognition.** An agent's memory is an AAAK diary. The diary records not just facts but patterns (`pattern:3rd.time`), importance assessments (star ratings), and emotion markers (`*fierce*`, `*raw*`). When an agent reads its diary in a new session, it isn't recalling what happened -- it's reconstructing its understanding of the domain. A reviewer agent that has reviewed 200 PRs, after reading its 10 most recent diary entries, has sharper code quality perception than a fresh AI with no history.

**Third layer: ecosystem.** Multiple agents accumulate domain expertise in the same palace, and their memories are connected through the palace's search and navigation infrastructure. Bug patterns found by the reviewer may relate to the architect's design decisions; incidents recorded by ops may corroborate the reviewer's code quality concerns. These connections don't need to be manually established -- they emerge naturally through shared semantic space and namespace.

These three layers together answer a bigger question: where should AI agent memory live?

In CLAUDE.md? That's configuration bloat -- every additional agent means another section in the configuration file. In separate databases? That's infrastructure bloat -- every additional agent means another storage instance to manage. In cloud services? That's cost bloat -- every additional agent means another line item on the monthly bill.

In one wing of the palace? That's a tag. The palace already has search, navigation, knowledge graph, and compression. The agent is simply a new consumer of these existing capabilities. It doesn't add infrastructure, doesn't add configuration, doesn't add monthly fees. It only adds memory -- and memory is the very reason the palace exists.
