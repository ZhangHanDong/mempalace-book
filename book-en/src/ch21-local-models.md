# Chapter 21: Local Model Integration

> **Positioning**: This chapter explains how MemPalace can run for long periods in an offline environment once local dependencies and default embedding assets are prepared -- from ChromaDB to local models to AAAK compression -- and why the entire stack was designed from day one with "no continuous network requirement" as a hard constraint rather than an optional feature.

---

## Offline Is Not a Degraded Mode

Most AI memory systems treat offline support as a degraded mode: the cloud version offers full functionality, while local operation trades away some features, some performance, and some fees. Mem0's core is a cloud API, with self-hosting available only as an enterprise option. Zep's knowledge graph runs on Neo4j, which can be set up locally but is recommended for cloud instances.

MemPalace's design direction is the complete opposite: **the main path is local, and cloud enhancement is a side path.** ChromaDB is an embedded vector database with data stored on the local filesystem. The knowledge graph uses SQLite, also a local file. AAAK compression is pure string manipulation, dependent on no external service. The MCP server runs over the stdio channel, involving no network. More precisely: once local dependencies and default embedding assets are prepared, you can store, search, wake up, and query the knowledge graph on a disconnected laptop; only benchmark paths like Haiku / Sonnet rerank add a cloud model.

This design isn't technical purism. It stems from a judgment about the nature of memory data: **personal memory is one of the most sensitive data types, and it should not require users to trust any third party.** Your technical decisions, team dynamics, personal preferences, project progress -- the aggregate of this information is more sensitive than any single document because it paints a complete portrait of your work. Hosting this portrait on someone else's server requires a very strong reason. And "convenience" is not a strong enough reason.

The topic of this chapter isn't "how to install and configure locally" -- that's documentation's job. The topic is: when the entire stack is local, what does the integration path between AI and memory look like?

---

## Path One: The Wake-Up Command

Look at the `cmd_wakeup` implementation at `cli.py:107-118`:

```python
def cmd_wakeup(args):
    """Show L0 (identity) + L1 (essential story)
    — the wake-up context."""
    from .layers import MemoryStack

    palace_path = (os.path.expanduser(args.palace)
                   if args.palace
                   else MempalaceConfig().palace_path)
    stack = MemoryStack(palace_path=palace_path)

    text = stack.wake_up(wing=args.wing)
    tokens = len(text) // 4
    print(f"Wake-up text (~{tokens} tokens):")
    print("=" * 50)
    print(text)
```

It does one simple thing: extracts L0 (identity) and L1 (key facts) from the palace and outputs them to the terminal. The user copies this text into the local model's system prompt, and the model now possesses the palace's core memory.

Command-line usage:

```bash
mempalace wake-up > context.txt
# Paste contents of context.txt into the local model's system prompt

mempalace wake-up --wing driftwood > context.txt
# Project-specific wake-up context
```

The internal logic of `MemoryStack.wake_up()` (`layers.py:380-399`) has two steps. Step one loads L0: reads `~/.mempalace/identity.txt` -- a user-written plain text file defining the AI's identity. Step two generates L1: pulls the 15 most important memories from ChromaDB (sorted by importance), groups them by room, truncates to a 3200-character limit, and formats them into compact text blocks.

By the current source baseline, that output is typically **~600-900 tokens**, and the CLI estimates it with a simple `len(text) // 4` heuristic before printing. The `~170 token` number that appears in the README describes a more aggressive later path: rewrite L1 into AAAK and then use that smaller representation for wake-up. In other words, "usable with local models" and "wake-up is only 170 tokens" are two different claims; the former is already true, the latter is not yet the default command path.

Why the name "wake-up" instead of "load-context" or "get-summary"? Because the semantics of this operation aren't "fetch data" but "wake up an agent with memory." When the local model loads this L0 + L1 text, it transforms from a generic model that knows nothing about the user into a personal assistant that knows who the user is, what projects they're working on, and what they care about. This is identity injection, not data transfer.

---

## Path Two: Python API

The wake-up command suits manual workflows -- the user switches back and forth between the terminal and a local model. But if you're building an automated pipeline -- say a locally running agent framework, or a custom chat interface -- you need a programming interface.

The `search_memories` function at `searcher.py:87-142` is the core of this interface:

```python
from mempalace.searcher import search_memories

results = search_memories(
    "auth decisions",
    palace_path="~/.mempalace/palace",
    wing="driftwood",
)
# results = {
#   "query": "auth decisions",
#   "filters": {"wing": "driftwood", "room": None},
#   "results": [
#     {"text": "...", "wing": "...", "room": "...",
#      "source_file": "...", "similarity": 0.87},
#     ...
#   ]
# }
```

It returns a dictionary rather than printing to the terminal. The `results` list in the dictionary contains the original text, spatial coordinates, source file, and similarity score for each matching memory. The caller takes this dictionary and injects the memory text into the prompt sent to the local model.

A typical integration pattern:

```python
from mempalace.searcher import search_memories
from mempalace.layers import MemoryStack

# 1. Load wake-up context
stack = MemoryStack()
wakeup = stack.wake_up()

# 2. Search for relevant memories on demand
results = search_memories("auth migration timeline")
memories = "\n".join(r["text"] for r in results["results"])

# 3. Assemble prompt, send to local model
prompt = f"""## Your Memory
{wakeup}

## Relevant Memories
{memories}

## User Question
Why did we choose Clerk over Auth0?
"""
# response = local_model.generate(prompt)
```

This code doesn't depend on any network request. `MemoryStack` reads data from local ChromaDB, `search_memories` does vector retrieval locally, prompt assembly is pure string concatenation, and `local_model.generate` calls locally running model inference. The entire chain completes end-to-end on the local machine.

Note that `search_memories` and the MCP server's `tool_search` actually call the same function (`mcp_server.py:173-180`). The MCP path and the Python API path converge at the same retrieval engine underneath. This means memories found through MCP with Claude and memories injected into local models through the Python API come from exactly the same data source and retrieval logic. There's no such thing as "MCP-version memories are better."

---

## Anatomy of an Offline-Capable Stack

Putting all components together, here's what an offline-capable MemPalace stack looks like after cold-start preparation:

**Storage layer: ChromaDB (embedded) + SQLite.** ChromaDB stores vector embeddings and documents on the local filesystem, defaulting to `~/.mempalace/palace`. What the repository directly proves is that MemPalace does not configure an external embedding service by default; it relies on ChromaDB's local embedding path. After that initial asset-preparation step, the path can keep running offline. The knowledge graph uses SQLite, stored at `~/.mempalace/knowledge_graph.sqlite3`. Both databases combined have minimal disk requirements -- a palace with 22,000 memories, including all data and indexes, is approximately 200-300MB.

**Compression layer: AAAK dialect.** Purely rule-driven text compression, dependent on no model. Entity names are replaced with three-letter codes, structured into pipe-delimited format, emotions marked with asterisks. A 30x compression ratio means 3000 tokens of natural language memory can be compressed to 100 tokens. This is especially important for local models with small context windows -- a 4K context model, after deducting system prompt and user input, may only have 2K tokens left for memory. AAAK lets those 2K tokens hold what would otherwise require 60K tokens.

**Interface layer: CLI + Python API.** `mempalace wake-up` outputs wake-up text, `mempalace search` outputs search results. Both commands output plain text that can be injected into any model via piping, redirection, or copy-paste. The Python API provides programmatic access, returning structured data for automated pipelines.

**Inference layer: the user's chosen local model.** MemPalace isn't tied to any specific model. Its output is text -- any model that can read text can consume it. This isn't a stance of technical neutrality but a natural consequence of architectural constraints: when your output format is plain text, your consumer can be any text processor, whether a 70B-parameter Llama or a 7B Mistral, whether local inference or an API call.

---

## Why This Design: Two Key Decisions

Looking back at this offline stack, two design decisions deserve deeper analysis.

### Decision One: Text as Interface, Not Tool Calls

Under the MCP path, AI accesses memory through tool calls -- structured input parameters, structured JSON returns. But under the local model path, the interface degrades to plain text. Wake-up output is text, search output is text, AAAK is text.

This appears to be a downgrade -- from a structured API to string copy-paste. But in reality, text is the most universally compatible interface format. JSON APIs require the consumer to understand the schema. Tool calls require the consumer to implement the MCP protocol. Text only requires the consumer to be able to read.

The deeper significance of this choice is: it doesn't require local models to have any "special capabilities." No function calling support needed, no tool use training needed, no JSON mode needed. A 7B model that's only been through basic text generation training can consume the current wake-up text directly. Today that usually costs about 600-900 tokens; if the AAAK wake-up path lands later, the barrier falls further.

### Decision Two: AAAK Is a Plain Text Protocol, Not an Encoding Format

There's an easily overlooked key property in AAAK's design: it doesn't need a decoder.

Compare other compression approaches. If you compress memory text with gzip, you get extremely high compression ratios, but LLMs can't directly read gzip binary. If you use custom token encoding -- say mapping "Alice" to a special token -- you need to modify the model's vocabulary or do a decoding pass before inference.

AAAK needs neither. `ALC=Alice` is a readable mapping. `|` is a visible delimiter. `★★★★` is an intuitively understandable rating. Any LLM -- regardless of its training data, vocabulary, or inference framework -- can directly read AAAK text and correctly understand its meaning.

This is the foundational assumption that makes the entire local stack viable. If AAAK required a decoding step, a preprocessor would need to be inserted into the local model's inference pipeline. A preprocessor means additional code, additional dependencies, additional failure points. Plain-text AAAK eliminates this layer -- memory flows from storage to consumption as an end-to-end plain text stream with no conversion steps in between.

---

## Trade-offs Between the Two Paths

The wake-up path and the Python API path aren't alternatives but complements. They serve different use cases.

**The wake-up path suits interactive use.** The user sits at the terminal, starts a new conversation, runs `mempalace wake-up`, pastes the output into the model's context, then begins the conversation. The entire process takes about 10 seconds, with an additional 600-900 tokens consumed under the current implementation. Suitable for everyday Q&A, brainstorming, and code review. Its advantage is zero integration cost -- no code to write, no configuration to change, no pipeline to build. The README's lighter `~170 token` number belongs to the next optimization stage of the same workflow.

**The Python API path suits automated pipelines.** A developer builds a custom agent framework -- perhaps a LangChain-based workflow, a custom CLI tool, or an IDE plugin -- using `search_memories` to automatically retrieve relevant memories before each conversation and inject them into the prompt. Additional token consumption depends on the number and length of search results, typically 500-2000 tokens. Suitable for scenarios requiring deep memory integration -- project retrospectives, decision tracing, knowledge base queries.

Both paths share the same palace. Memories seen in wake-up and memories retrieved via the API come from the same ChromaDB instance. Switching paths requires no data migration, no re-indexing, no format conversion. The palace is the single source of truth -- the access method is interchangeable.

---

## The Cost and Return of Going Offline

To be honest, running completely offline has costs.

**The cost of embedding quality.** ChromaDB's default all-MiniLM-L6-v2 is a small embedding model. Its semantic understanding capability doesn't match OpenAI's text-embedding-3-large or Cohere's embed-v3. In extreme semantic matching scenarios -- such as searching for a memory containing "Auth0's pricing became unsustainable when users exceeded ten thousand" with the query "why did we abandon the old authentication system" -- the small model might miss what a large model wouldn't. MemPalace compensates for this gap through palace structure filtering: when you tell the search "look in the auth-migration room of wing_driftwood," the search space shrinks to a few dozen memories, and the small model's accuracy within this range is comparable to the large model's. This is also why the palace structure delivers a 34% retrieval improvement -- structure compensates for the model.

**The cost of reasoning capability.** Local models' reasoning capabilities are typically weaker than cloud-based large models. A 7B-parameter model may not be able to precisely understand pattern markers in AAAK diary entries, correctly infer temporal relationships, or judge between multiple contradictory memories the way Claude can. But MemPalace's design philosophy is: **let the storage layer do storage's job, and let the reasoning layer do reasoning's job.** If memories are correctly retrieved and presented to the model, even if the model's reasoning capability is limited, it's at least reasoning on a correct factual basis. This is far better than a response with strong reasoning ability but based on hallucinations.

**The returns are certain.** Privacy protection -- your memories never leave your machine. Zero operating cost -- aside from electricity, there are no monthly fees. Unlimited availability -- no dependency on network connectivity, no API rate limiting, no loss of memory due to service outages. And a deeper return: sovereignty. Your memory system is unaffected by any third party's pricing decisions, privacy policy changes, or service shutdowns. It runs on your hard drive, with your chosen model, outputting text you control.

This isn't a trade-off every user needs. If your memory content isn't sensitive, the convenience of cloud solutions may be more valuable. But for users whose memory content involves business decisions, team dynamics, and personal life -- and these are precisely the most valuable use cases for a memory system -- offline capability isn't an optional feature but a prerequisite.

MemPalace's entire technology stack is designed around this prerequisite. ChromaDB instead of Pinecone, SQLite instead of Neo4j, AAAK instead of GPT summaries, stdio instead of HTTP. Every technical choice points in the same direction: your memory should belong entirely to you, whether or not you're connected to the internet.
