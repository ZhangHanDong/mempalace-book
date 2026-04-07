# Chapter 14: L0-L3 -- The Layered Design of the Four-Tier Memory Stack

> **Positioning**: This chapter dissects the design rationale and implementation of MemPalace's four-tier memory stack. We will analyze layer by layer what problem each solves, how many tokens it consumes, when it loads, and why four layers rather than some other number. Source code analysis is based on `mempalace/layers.py`.

---

## A Question About "Waking Up"

When your AI assistant starts a fresh session from scratch, it knows nothing about you. It does not know your name, does not know what project you are working on, does not know you made a critical architectural decision yesterday. Every new session is a complete amnesia.

The naive solution to this problem is: stuff all conversation history into the context window. But as analyzed in earlier chapters of this book, six months of daily AI use produces approximately 19.5 million tokens -- far exceeding any model's context window. Even if context windows expand to 100 million tokens in the future, this brute-force loading approach has a fundamental cost problem: every conversation would bill for millions of tokens, 99% of which are useless in the current conversation.

Another common approach is having the LLM extract "important information" after each conversation and save it as summaries. But as we have repeatedly discussed, this method introduces irreversible information loss at the storage stage.

MemPalace's answer is a four-tier memory stack: not storing more, not storing less, but loading the right amount at the right time.

---

## Why "Stack" Rather Than "Database"

Before discussing the specific layers, it is worth understanding why MemPalace chose the "stack" metaphor.

A traditional database is flat: all data lives on the same level, extracted on demand via query language. But human memory does not work this way. You do not need to recall your own name -- that information is always on the surface of consciousness; you do not need to deliberately think about what you did this morning -- these recent experiences are readily available in "working memory"; but if someone asks about details of a trip three years ago, you need to actively "search" long-term memory.

This layering is not accidental. Cognitive science divides human memory into sensory memory, short-term (working) memory, and long-term memory, each with different capacity, duration, and retrieval cost. MemPalace's four-tier stack directly maps this cognitive structure -- not because biomimicry is the goal, but because this layering happens to solve practical engineering problems in AI context management.

The core question is: **how to maximize information utility within a limited token budget?**

The answer is to layer by frequency and urgency. Some information is needed in every conversation ("who I am"), some only when a specific topic comes up ("recent discussions about this project"), and some only when explicitly asked ("the discussion about GraphQL last March"). Treating them all at the same level is either too expensive, too slow, or both.

---

## The Four-Tier Overview

Before diving into the details of each layer, here is the complete stack structure:

| Layer | Content | Typical Size | Load Timing | Design Motivation |
|------|------|---------|---------|---------|
| L0 | Identity -- "Who am I" | ~50-100 tokens | Always loaded | AI needs to know its role and basic relationships |
| L1 | Key facts -- the most important memories | ~500-800 tokens (current implementation) | Always loaded | Minimum viable context: team, project, core preferences |
| L2 | Room recall -- on-demand retrieval | ~200-500 tokens/retrieval | On explicit `recall()` | A batch of relevant context for the current topic |
| L3 | Deep search -- semantic retrieval | Unlimited | On explicit query | Full semantic search across all data |

```mermaid
graph TB
    subgraph "Always Loaded"
        L0["L0 Identity<br/>~50 tokens"]
        L1["L1 Key Facts<br/>~500-800 tokens (current)"]
    end
    subgraph "On-Demand Loading"
        L2["L2 Room Recall<br/>~200-500 tokens"]
        L3["L3 Deep Search<br/>Unlimited"]
    end
    L0 --> L1
    L1 -.->|explicit recall by higher layer| L2
    L2 -.->|explicit semantic query| L3
```

In the current v3.0.0 source baseline, L0 + L1 produce a wake-up cost of roughly 600-900 tokens. The README also presents a more aggressive target figure: if AAAK is fully connected to the wake-up path, L0 + L1 can be pushed to about 170 tokens. The two should not be conflated. In the rest of this chapter, discussion of `layers.py` reflects the 600-900-token current state; discussion of longer-term compression direction refers to the README's 170-token target.

That means: even without AAAK on the default path, MemPalace's wake-up remains a relatively cheap persistent context layer; the README's 170-token version represents the upper bound once the compression path is fully wired through.

---

## L0: The Identity Layer

```
Layer 0: Identity       (~100 tokens)   -- Always loaded. "Who am I?"
```

L0 is the simplest layer in the entire stack and also the most indispensable. It answers a fundamental question: **who is this AI assistant?**

In the `layers.py` implementation, the `Layer0` class reads identity information from a plain text file (`layers.py:34-69`):

```python
class Layer0:
    """
    ~100 tokens. Always loaded.
    Reads from ~/.mempalace/identity.txt -- a plain-text file the user writes.
    """
    def __init__(self, identity_path: str = None):
        if identity_path is None:
            identity_path = os.path.expanduser("~/.mempalace/identity.txt")
        self.path = identity_path
        self._text = None

    def render(self) -> str:
        if self._text is not None:
            return self._text
        if os.path.exists(self.path):
            with open(self.path, "r") as f:
                self._text = f.read().strip()
        else:
            self._text = (
                "## L0 -- IDENTITY\n"
                "No identity configured. Create ~/.mempalace/identity.txt"
            )
        return self._text
```

Several design choices are worth noting.

**Plain text, user-written.** Identity is not automatically extracted from conversations but written by the user themselves. This is a deliberate decision. Identity is declarative knowledge -- "I am Atlas, Alice's personal AI assistant" -- that does not need to be mined from massive conversations. Having users define their own identity means identity is always precise, intentional, and controllable.

**Filesystem, not database.** L0 reads from `~/.mempalace/identity.txt` -- an ordinary text file editable with any text editor. This eliminates all the complexity of "how to update identity." Want to change the identity? Edit the file.

**Cached reading.** The `render()` method uses `_text` for simple caching (`layers.py:52-65`). The file is read only once; afterward, the cached content is returned directly. This is sufficient for L0 -- identity does not change during a session.

**Graceful degradation.** If the identity file does not exist, L0 does not error out but returns prompt text guiding the user to create the file (`layers.py:61-63`). The system can always start, regardless of whether configuration is complete.

**Token estimation.** The `token_estimate()` method uses a simple heuristic: character count divided by 4 (`layers.py:67-68`). This is not a precise tokenizer calculation but a good-enough approximation. At L0's scale (typically a few dozen to a hundred tokens), this precision is perfectly acceptable.

A typical identity.txt looks roughly like this:

```
I am Atlas, a personal AI assistant for Alice.
Traits: warm, direct, remembers everything.
People: Alice (creator), Bob (Alice's partner).
Project: A journaling app that helps people process emotions.
```

This is approximately 50 tokens. It looks trivial, but it gives the AI a crucial anchor: it knows "who" it is, "whom" it serves, and what its behavioral style should be. Without this anchor, every conversation would need to begin by re-establishing the relationship from "Hello, I am your AI assistant."

---

## L1: The Key Facts Layer

```
Layer 1: Essential Story (~500-800)  -- Always loaded. Top moments from the palace.
```

If L0 is "who am I," L1 is "what are the most important things I know."

L1's design goal is to load the core facts most likely to be useful in the current conversation within the smallest possible token budget. It does not need to contain all memories -- that is L3's job -- but rather provides a "minimum viable context" that allows the AI to appear as if it "remembers you" without any active searching.

In `layers.py:76-168`, the `Layer1` class implementation reveals several key design decisions:

**Auto-generated, not manually maintained.** Unlike L0, L1 does not require the user to write it by hand. It automatically extracts the most important memory fragments from ChromaDB's palace data (`layers.py:91-168`).

**Importance ranking.** L1 uses a scoring mechanism to decide which memories are most worth loading. The scoring logic is at `layers.py:116-128`:

```python
scored = []
for doc, meta in zip(docs, metas):
    importance = 3
    for key in ("importance", "emotional_weight", "weight"):
        val = meta.get(key)
        if val is not None:
            try:
                importance = float(val)
            except (ValueError, TypeError):
                pass
            break
    scored.append((importance, meta, doc))

scored.sort(key=lambda x: x[0], reverse=True)
top = scored[: self.MAX_DRAWERS]
```

The code tries to read importance scores from multiple metadata keys -- `importance`, `emotional_weight`, `weight` -- reflecting a pragmatic compatibility strategy: data from different sources may use different key names to mark importance, and L1 tries each in sequence, using the first valid value found. The default value is 3 (moderate importance), ensuring that even without explicit marking, memories can participate in ranking.

**Grouped by room.** The top N memories after sorting are not simply listed in a flat list but grouped by room for display (`layers.py:135-139`):

```python
by_room = defaultdict(list)
for imp, meta, doc in top:
    room = meta.get("room", "general")
    by_room[room].append((imp, meta, doc))
```

This design gives L1's output structure -- the AI does not see a jumble of scattered facts but information organized by topic. This aligns with the memory palace's core concept: spatial structure itself is the index.

**Hard token limits.** L1 has two hard constraints: maximum 15 memories (`MAX_DRAWERS = 15`), and total characters not exceeding 3200 (`MAX_CHARS = 3200`, approximately 800 tokens). When approaching the limit, the generation process gracefully truncates and adds a `"... (more in L3 search)"` hint telling the AI it can get more through deep search (`layers.py:160-163`).

**Why ~500-800 tokens in the current implementation, and ~120 in the README's AAAK target?** This range was not chosen arbitrarily. The README indicates a design goal of keeping total wake-up cost (L0 + L1) around 170 tokens. In that future path, AAAK would compress L1 to roughly 120 tokens while preserving a compact representation of team members, current projects, key decisions, and core preferences. Without AAAK on the current default path, the same information volume occupies 500-800 tokens, which is still manageable.

The budget was derived backwards from capability: first define what the AI should be able to answer immediately after waking up (who you are, who your team is, what project you are working on, what important decisions and recent high-weight memories matter), then estimate the minimum information needed to support that.

---

## L2: The On-Demand Retrieval Layer

```
Layer 2: On-Demand      (~200-500 each)  -- Loaded on explicit recall.
```

L2 is the middle ground between "passive memory" and "active search."

L0 and L1 are always present, forming the AI's "resident awareness." L3 is deep search, requiring explicit queries. L2 sits between both: a lightweight filtered recall path that a higher layer can call once it already knows which wing / room is relevant.

In `layers.py:176-233`, `Layer2`'s implementation is quite straightforward:

```python
class Layer2:
    """
    ~200-500 tokens per retrieval.
    Loaded when a higher layer explicitly asks for a specific wing / room.
    Queries ChromaDB with a wing/room filter.
    """
    def retrieve(self, wing: str = None, room: str = None, 
                 n_results: int = 10) -> str:
```

L2's core mechanism is **filtering rather than searching**. It does not use semantic queries but narrows scope through metadata filtering (wing and room) (`layers.py:195-205`):

```python
where = {}
if wing and room:
    where = {"$and": [{"wing": wing}, {"room": room}]}
elif wing:
    where = {"wing": wing}
elif room:
    where = {"room": room}

kwargs = {"include": ["documents", "metadatas"], "limit": n_results}
if where:
    kwargs["where"] = where

results = col.get(**kwargs)
```

Note this uses `col.get()` rather than `col.query()`. `get()` is ChromaDB's metadata filtering method, involving no vector similarity computation -- it simply returns documents matching the conditions. This means L2 retrieval is deterministic and has zero semantic overhead. Once the higher layer knows it wants `wing=driftwood`, L2 does not need to do semantic understanding; it only needs to fetch the matching records.

**Why 200-500 tokens?** This range corresponds to a small batch of room- or wing-filtered memory fragments. Each fragment is truncated to under 300 characters (`layers.py:226-228`), and with metadata tags, the total stays around one or two paragraphs. It is enough for the AI to reload a narrow local slice of context without crowding out the conversation itself.

L2 solves a subtle but important orchestration problem: without it, a higher layer must choose between keeping only shallow L1 awareness or jumping straight to full semantic search every time it already knows the relevant wing / room. In the current version, that benefit appears as an explicit API, not as automatic topic listening.

---

## L3: The Deep Search Layer

```
Layer 3: Deep Search    (unlimited)      -- Full ChromaDB semantic search.
```

L3 is the only layer that uses semantic search.

The previous three layers all perform "pre-loading" -- based on rules and structure, automatically injecting relevant information before conversation begins or when topics switch. L3 is different: it is an on-demand, full-corpus search, used to answer questions that require retrieval across the entire memory store.

`Layer3`'s core method `search()` is at `layers.py:251-303`:

```python
class Layer3:
    """
    Unlimited depth. Semantic search against the full palace.
    """
    def search(self, query: str, wing: str = None, 
               room: str = None, n_results: int = 5) -> str:
        # ...
        kwargs = {
            "query_texts": [query],
            "n_results": n_results,
            "include": ["documents", "metadatas", "distances"],
        }
        if where:
            kwargs["where"] = where

        results = col.query(**kwargs)
```

Here `col.query()` is used -- ChromaDB's semantic search method. It converts the query text into a vector, ranks the entire collection by cosine similarity, and returns the closest results.

L3's output format design is also noteworthy (`layers.py:287-303`):

```python
lines = [f'## L3 -- SEARCH RESULTS for "{query}"']
for i, (doc, meta, dist) in enumerate(zip(docs, metas, dists), 1):
    similarity = round(1 - dist, 3)
    wing_name = meta.get("wing", "?")
    room_name = meta.get("room", "?")
    # ...
    lines.append(f"  [{i}] {wing_name}/{room_name} (sim={similarity})")
    lines.append(f"      {snippet}")
```

Each result includes three types of information: location (wing/room), similarity score, and content snippet. Location information tells the AI "where in the palace" this memory lives, the similarity score lets the AI judge the result's reliability, and the content snippet provides the actual information.

**Relationship with `searcher.py`.** The L3 implementation in `layers.py` and the search functionality in `searcher.py` are logically overlapping. `searcher.py` provides two functions: `search()` (prints formatted output, `searcher.py:15-84`) and `search_memories()` (returns structured data, `searcher.py:87-142`). Both use the same ChromaDB `query()` call, differing only in output format -- the former for CLI, the latter for programmatic calls such as the MCP server.

L3 also provides a `search_raw()` method (`layers.py:305-352`) that returns raw dictionary lists instead of formatted text. This provides a flexible data interface for upper-layer applications (such as MCP tools).

---

## Unified Interface: MemoryStack

The four layers are exposed through a unified `MemoryStack` class (`layers.py:360-438`):

```python
class MemoryStack:
    def __init__(self, palace_path=None, identity_path=None):
        self.l0 = Layer0(self.identity_path)
        self.l1 = Layer1(self.palace_path)
        self.l2 = Layer2(self.palace_path)
        self.l3 = Layer3(self.palace_path)

    def wake_up(self, wing=None) -> str:
        """L0 (identity) + L1 (essential story). ~600-900 tokens."""
        parts = []
        parts.append(self.l0.render())
        parts.append("")
        if wing:
            self.l1.wing = wing
        parts.append(self.l1.generate())
        return "\n".join(parts)

    def recall(self, wing=None, room=None, n_results=10) -> str:
        """On-demand L2 retrieval."""
        return self.l2.retrieve(wing=wing, room=room, n_results=n_results)

    def search(self, query, wing=None, room=None, n_results=5) -> str:
        """Deep L3 semantic search."""
        return self.l3.search(query, wing=wing, room=room, n_results=n_results)
```

Three methods, three usage scenarios:

- `wake_up()`: Called once at the start of each session. Injected into the system prompt or first message.
- `recall()`: Called on topic changes. When conversation involves a specific project or domain, loads related memories.
- `search()`: Called on explicit user questions. Semantic retrieval across all data.

The `wake_up()` method also supports a wing parameter (`layers.py:380-399`), allowing L1 content to be filtered by project. If you are working on Driftwood, `wake_up(wing="driftwood")` loads only key facts related to Driftwood, further reducing token consumption while improving information relevance.

The `status()` method (`layers.py:409-438`) provides overall stack diagnostics, including whether the identity file exists, token estimates, and total memory count. This is useful for debugging and operations.

---

## Why Four Layers, Not Two or Eight

This is a design question worth answering seriously.

**Why not two layers (always-loaded + search)?** Because an important gray area exists between "always loaded" and "search." Imagine a system with only L0+L1 and L3: your AI knows your name and current project (L1), and can search if asked specific questions (L3), but when the higher layer already knows "we are talking about Driftwood," it still has to jump directly to full semantic search. L2 fills that gap by making wing/room recall a separate lightweight path. In the current version, the gain appears as an explicit API rather than automatic topic listening.

**Why not three layers (dropping L0, merging identity into L1)?** Because identity and facts are fundamentally different in nature. Identity is declarative, user-controlled, and almost never changes. L1's key facts are auto-generated from data, ranked by importance, and updated as new data arrives. Mixing them together means either user identity declarations get crowded out by auto-generated content, or auto-generation logic must carefully avoid the user-written portions. Separating them is cleaner.

**Why not more layers?** Because each additional layer adds a "when to load" decision point. Four layers already cover the critical timing semantics: always (L0, L1), filtered recall (L2), and explicit search (L3). It is hard to define a fifth meaningful loading trigger. If you try to split L2 into "recent topics" and "older topics," or split L3 into "shallow search" and "deep search," the complexity introduced would likely exceed the benefit.

Four layers is a **minimum complete set**: one fewer means missing functionality, one more means over-engineering.

---

## The Economics of Token Budgets

Finally, let us do the math.

If you calculate strictly from today's `layers.py`, MemPalace's default wake-up cost is ~600-900 tokens, not 170. The README's `~170 token / ~$0.70 per year` figure represents the target economics after AAAK is connected to the main wake-up path, not the current measured output of `mempalace wake-up`.

But that does not change the important principle here: **the best cost optimization is not making each call cheaper, but making most calls not happen at all.**

Whether today's cost is 600-900 tokens or the README's future 170-token path, L0 + L1 are not trying to stuff all history into every conversation. They select only the small amount worth keeping resident all the time. Through four-layer separation, the vast majority of memories never need to be loaded into any single conversation. They sit quietly in ChromaDB, appearing through L2 or L3 only when explicitly needed.

That is the value of layering: not storing less, but loading the right amount at the right time. The full six months of memory are still there, with nothing deleted. In today's implementation, the AI wakes up with 600-900 tokens; on the README's compression roadmap, it could eventually do the same job for less.

The stack is not a filing cabinet. It is a layered decision system about "what is worth remembering right now."
