# Chapter 18: The Art of Chunking

> **Positioning**: Half of a vector database's retrieval quality depends on the chunking strategy. Chunks too large fill search results with irrelevant content; chunks too small fracture semantics. This chapter covers MemPalace's two chunking strategies -- fixed windows for project files, Q&A pairs for conversations -- and why conversation text cannot use fixed windows.

---

## Why Chunking Is a Problem

Vector retrieval works like this: convert text fragments into vectors, store them in a database; at query time, convert the question into a vector and find the nearest matches.

What if you skip chunking and store an entire file as a single vector? Two problems arise. First, embedding models have length limits -- most models can only process 512 or 8192 tokens, truncating anything beyond that. Second, even if a model could handle long text, the embedding vector of a long document becomes an "average" of all its topics -- a document that simultaneously discusses database design, deployment strategy, and team management will have its vector land in the middle of all three topics, meaning a search on any single topic will barely find it.

So you must chunk. The question is how.

MemPalace's answer to this problem is: **project files and conversation files need different chunking strategies because their minimum semantic units differ.**

---

## Project File Chunking: Fixed Window + Paragraph Awareness

The `chunk_text()` function in `miner.py` (`miner.py:135`) handles project file chunking. Its parameters are defined at the top of the file (`miner.py:56-58`):

```python
CHUNK_SIZE = 800    # chars per drawer
CHUNK_OVERLAP = 100  # overlap between chunks
MIN_CHUNK_SIZE = 50  # skip tiny chunks
```

800 characters is roughly 150-200 English words, equivalent to a medium-sized paragraph. The choice of 800 rather than a larger value (say 2000) is because project file content is typically compact -- a Python function, a README section, a configuration block. 800 characters is enough to contain a complete logical unit while being small enough to keep retrieval results precise.

The 100-character overlap handles sentences that happen to be split at boundaries. If an important sentence straddles two chunks, the overlap ensures the last 100 characters of the first chunk and the beginning of the next chunk are the same. This means the sentence is complete in at least one chunk.

But `chunk_text()` doesn't mechanically cut every 800 characters. It has paragraph-aware logic (`miner.py:153-161`):

```python
if end < len(content):
    # 优先在双换行（段落边界）处切割
    newline_pos = content.rfind("\n\n", start, end)
    if newline_pos > start + CHUNK_SIZE // 2:
        end = newline_pos
    else:
        # 退而求其次，在单换行处切割
        newline_pos = content.rfind("\n", start, end)
        if newline_pos > start + CHUNK_SIZE // 2:
            end = newline_pos
```

It first tries to cut at double newlines (paragraph boundaries). If a double newline is found in the range `[start + 400, start + 800]`, it cuts there. If no double newline is found, it looks for a single newline. Only if no newline is found at all (e.g., an extremely long unbroken line of text) does it hard-cut at 800 characters.

The `start + CHUNK_SIZE // 2` lower bound (i.e., 400 characters) prevents a problem: if a paragraph boundary appears at the very beginning of a chunk (say at character 10), cutting there would produce an extremely small chunk, wasting storage space and retrieval resources. Requiring the cut point to be at least in the second half of the chunk ensures every chunk has sufficient content.

Finally, chunks that are too short (fewer than 50 characters) are skipped (`miner.py:164`). Blank lines and single-line comments aren't worth being standalone retrieval units.

---

## Conversation Chunking: Q&A Pairs as the Minimum Semantic Unit

Now let's look at conversation file chunking. The `chunk_exchanges()` function in `convo_miner.py` (`convo_miner.py:52`) takes an entirely different approach.

### Why Conversations Cannot Use Fixed Windows

Suppose you have this conversation:

```
> What factors should we consider for our database selection?
Consider three dimensions: first, query patterns -- whether you're primarily OLTP or OLAP;
second, data scale -- projected data volume over the next year; third, team familiarity.

> How does PostgreSQL compare to MySQL?
PostgreSQL is stronger in complex queries and JSON support, while MySQL is more mature
in simple read/write operations and its operational ecosystem. Given your JSON data needs,
I'd recommend PostgreSQL.
```

If you apply an 800-character fixed window, the possible result is:

```
[Chunk 1]
> What factors should we consider for our database selection?
Consider three dimensions: first, query patterns -- whether you're primarily OLTP or OLAP;
second, data scale -- projected data volume over the next year; third, team familiarity.
> How does PostgreSQL compare to MySQL?

[Chunk 2]
PostgreSQL is stronger in complex queries and JSON support, while MySQL is more mature
in simple read/write operations and its operational ecosystem. Given your JSON data needs,
I'd recommend PostgreSQL.
```

The problem is in the last line of Chunk 1: the question "How does PostgreSQL compare to MySQL?" is grouped into Chunk 1, but its answer is in Chunk 2. If a user later searches for "PostgreSQL vs MySQL," Chunk 1 matches the question but doesn't contain the answer, while Chunk 2 contains the answer but lacks the question's context. Neither chunk is complete.

This is why conversations need to be chunked by Q&A pairs. A question and its response are an indivisible semantic unit -- the question defines context, the response provides information. Splitting them apart, both sides lose meaning.

### Q&A Pair Chunking Implementation

The `_chunk_by_exchange()` function (`convo_miner.py:66`) works as follows:

```python
def _chunk_by_exchange(lines: list) -> list:
    chunks = []
    i = 0
    while i < len(lines):
        line = lines[i]
        if line.strip().startswith(">"):
            # 找到一个用户发言
            user_turn = line.strip()
            i += 1
            # 收集紧跟其后的 AI 回复
            ai_lines = []
            while i < len(lines):
                next_line = lines[i]
                if next_line.strip().startswith(">") or next_line.strip().startswith("---"):
                    break
                if next_line.strip():
                    ai_lines.append(next_line.strip())
                i += 1
            # 合并为一个分块
            ai_response = " ".join(ai_lines[:8])
            content = f"{user_turn}\n{ai_response}" if ai_response else user_turn
            if len(content.strip()) > MIN_CHUNK_SIZE:
                chunks.append({"content": content, "chunk_index": len(chunks)})
        else:
            i += 1
    return chunks
```

Several details are worth noting:

**Chunk boundaries are driven by the `>` marker.** Upon encountering a `>` line, it begins collecting a Q&A pair. It continues reading downward until the next `>` line (the next question) or a `---` separator. All non-empty lines in between are the AI's response.

**AI responses are truncated to the first 8 lines** (`convo_miner.py:86`). This is an intentional limitation -- `" ".join(ai_lines[:8])`. Why? Because AI responses can be very long (dozens or even hundreds of lines of code, detailed step-by-step explanations), but for vector retrieval, the first few lines typically contain the core answer. Stuffing an entire lengthy response into a single chunk dilutes the vector's semantic focus.

**Empty lines are skipped** (`convo_miner.py:81`). Only lines where `next_line.strip()` is non-empty are collected. This ensures chunk content is compact with no meaningless whitespace.

**`---` separators serve as hard boundaries** (`convo_miner.py:80`). If the conversation contains `---` separator lines (common in Markdown-formatted conversation logs), they terminate the current Q&A pair collection even if the following content doesn't start with `>`. This is because `---` typically indicates a topic change or conversation segment break.

### Fallback: Paragraph Chunking

If the text doesn't have enough `>` markers (fewer than 3), `chunk_exchanges()` falls back to `_chunk_by_paragraph()` (`convo_miner.py:102`):

```python
def _chunk_by_paragraph(content: str) -> list:
    chunks = []
    paragraphs = [p.strip() for p in content.split("\n\n") if p.strip()]
    if len(paragraphs) <= 1 and content.count("\n") > 20:
        lines = content.split("\n")
        for i in range(0, len(lines), 25):
            group = "\n".join(lines[i : i + 25]).strip()
            if len(group) > MIN_CHUNK_SIZE:
                chunks.append({"content": group, "chunk_index": len(chunks)})
        return chunks
    for para in paragraphs:
        if len(para) > MIN_CHUNK_SIZE:
            chunks.append({"content": para, "chunk_index": len(chunks)})
    return chunks
```

This fallback handles two cases:

1. **Text with paragraph separators** (double newline separated): each paragraph becomes a chunk.
2. **Long text without paragraph separators** (more than 20 lines but no double newlines): every 25 lines becomes a chunk.

The number 25 isn't arbitrary -- it roughly corresponds to 800 characters (assuming 30-35 characters per line), keeping it consistent with the project file chunk size.

---

## Parameter Comparison of the Two Strategies

| Parameter | Project Files (miner.py) | Conversation Files (convo_miner.py) |
|-----------|------------------------|-------------------------------------|
| Chunk unit | Fixed window (800 chars) | Q&A pair (variable size) |
| Overlap | 100 chars | None (no overlap between Q&A pairs) |
| Boundary awareness | Paragraph boundaries (double newline > single newline) | `>` markers + `---` separators |
| Minimum chunk | 50 chars | 30 chars |
| AI response truncation | N/A | First 8 lines |
| Fallback | None (hard cut) | Paragraph chunking / 25-line groups |

Conversation chunking doesn't need overlap because Q&A pairs are naturally separated -- the problem of "sentences straddling chunk boundaries" doesn't exist between Question A's answer and Question B's answer. Each Q&A pair is self-contained.

The conversation chunking minimum threshold (30 characters) is lower than for project files (50 characters) because a brief but meaningful Q&A pair -- such as "> What language?\nPython." -- is only about 20 characters but carries valuable information.

---

## Room Routing: Classification After Chunking

After project file chunking, each chunk needs to be routed to its corresponding "room." The `detect_room()` function (`miner.py:89`) uses a three-level priority strategy:

1. **File path matching**: if the file is under the `docs/` directory and there's a room called "docs," route directly to that room
2. **Filename matching**: if the filename contains a room name
3. **Content keyword scoring**: use the room's keyword list to do keyword counting on the first 2000 characters of the content

Conversation file room routing is different. The `detect_convo_room()` function (`convo_miner.py:194`) uses five predefined topic categories:

```python
TOPIC_KEYWORDS = {
    "technical":    ["code", "python", "function", "bug", ...],
    "architecture": ["architecture", "design", "pattern", ...],
    "planning":     ["plan", "roadmap", "milestone", ...],
    "decisions":    ["decided", "chose", "switched", ...],
    "problems":     ["problem", "issue", "broken", ...],
}
```

These five categories aren't arbitrary -- they correspond to the five types of topics developers most commonly discuss in conversations. If no keywords match, it falls back to "general."

---

## Normalization and Chunking Pipeline

The conversation file processing flow is a clear pipeline (`convo_miner.py:302-317`):

```
Raw file → normalize() → chunk_exchanges() → store in ChromaDB
```

`normalize()` ensures uniform formatting of content entering the chunker (see Chapter 16), and `chunk_exchanges()` ensures each chunk is a complete semantic unit. Each chunk is stored as a "drawer" in ChromaDB, tagged with metadata such as wing, room, and source_file.

It's worth noting that the conversation miner supports two extraction modes (`convo_miner.py:259`): `"exchange"` (the default Q&A pair chunking) and `"general"` (a general-purpose extractor that extracts specific types of memories such as decisions, preferences, and milestones). The general extraction mode's chunked results come with a `memory_type` field that is used directly as the room name, bypassing `detect_convo_room()`'s topic classification.

---

## Summary

Chunking may look like a simple "split text" operation, but where you split, how large the pieces are, and what constitutes a unit directly determines downstream retrieval quality.

MemPalace's two chunking strategies reflect a fundamental insight: **different types of text have different minimum semantic units.** The minimum semantic unit of project files is a paragraph -- a block of code, a section of documentation, a configuration block. The minimum semantic unit of conversations is a Q&A pair -- the question defines context, the response provides information, and splitting them apart makes both sides lose meaning.

Key design points:

- **Project files**: 800-character window + 100-character overlap + paragraph boundary awareness
- **Conversation files**: Q&A pair chunking delimited by `>` markers, AI responses truncated to the first 8 lines
- **Both strategies share one principle**: cut at natural boundaries whenever possible, avoiding semantic fragmentation
- **Fallback strategy**: when conversations lack `>` markers, degrade to paragraph chunking to ensure any input can be processed
